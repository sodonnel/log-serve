require 'digest'

module LogServe
  module Models
    class LogFile

      attr_reader :key, :last_io_position, :file_path

      def initialize(file_path)
        @file_path = file_path
        set_key
        @index     = nil
      end

      def filename
        File.basename @file_path
      end

      # Note that for reading backwards, the lines come out oldest
      # first, so they really need to be reversed before being displayed
      def read_lines_backwards_from_position(num_to_read, pos, &blk)
        begin
          open pos
          reader = LogMerge::ReverseLogReader.new(@fh)
          read_lines(reader, num_to_read, &blk)
        ensure
          close
        end
      end

      def read_lines_from_position(num_to_read, pos, &blk)
        begin
          open pos
          reader = LogMerge::LogReader.new(@fh)
          read_lines(reader, num_to_read, &blk)
        ensure
          close
        end
      end

      # Testing on a 200MB file - converting each line to a log reader is takes about 12 - 15 seconds
      # to search the file. Just doing a regex on each line searches it in about 2 - 3 seconds even
      # with reading one line backwards to find the start position of the line.
      def position_for_match(start_pos, regex, forwards=true)
        begin
          matching_line = nil
          open(start_pos)
          fr = @fh
          if !forwards
            fr = LogMerge::ReverseFileReader.new(@fh)
          end
          fr.each_line do |line|
            if regex.match line
              matching_line = line
              break
            end
          end
          if matching_line.nil?
            nil
          else
            start_pos = fr.pos
            if !forwards
              # If searching backwards, if the match is found, in the file line that the log starts on, eg
              # DATE LEVEL .... match ....
              # Then the fh.pos will give the start of that line and reading backwards from there will give
              # the previous line to the match. So we need to adjust the positing forwards by the line length
              # and read back from there to find the correct line
              start_pos += matching_line.length
            end
            read_lines_backwards_from_position(1, start_pos).first.start_file_position
          end
        ensure
          close
        end
      end

      
      def position_at_time(dtm)
        start_line = read_lines_from_position(1, 0).first
        end_line   = read_lines_backwards_from_position(1, eof_position).first
        if start_line.timestamp > dtm || end_line.timestamp < dtm
          return nil
        end
        search_for_time_internal(dtm, start_line, end_line).start_file_position
      end

      def eof?
        @eof
      end

      def eof_position
        begin
          open
          @fh.seek(0, IO::SEEK_END)
          @fh.pos
        ensure
          close
        end
      end

      def open(pos=0)
        if @fh.nil? || @fh.closed?
          @fh = File.open(@file_path, 'r')
        end
        @fh.seek(pos, IO::SEEK_SET)
      end

      def close
        if @fh && !@fh.closed?
          @fh.close
        end
      end
      
      def indexed?
        @index || File.exists?(index_path)
      end

      def load_index
        unless indexed?
          raise "No index exists. Please build the index"
        end
        @index ||= LogMerge::Index.new.load(index_path)
      end

      def build_index
        index = LogMerge::Index.new
        read_lines_from_position(0, 0) do |l|
          index.index(l, p)
        end
        index.save(index_path)
      end

      private

      def index_path
        "#{@file_path}.idx"
      end

      def set_key
        @key = Digest::MD5.hexdigest @file_path
      end
      
      def read_lines(reader, num_to_read)
        @eof = false

        lines = []
        begin
          pos = reader.io_position
          while line = reader.next
            lfl = LogFileLine.new(line, pos, reader.io_position)
            pos = reader.io_position
            if block_given?
              yield lfl
            else
              lines.push lfl
              if lines.length >= num_to_read
                return lines
              end
            end
          end
        ensure
          @last_io_position = reader.io_position
        end
        # if we get here, it means we hit EOF before
        # returning the lines array as the iterator eventually returned nil
        @eof = true

        lines
      end

      def search_for_time_internal(dtm, start_line, end_line)
        middle = ((end_line.start_file_position + start_line.start_file_position) / 2).floor
        middle_line = read_lines_backwards_from_position(1, middle).first

        if ((start_line.start_file_position == middle_line.start_file_position) || (end_line.start_file_position == middle_line.start_file_position))
          
          return_line = middle_line

          # If we get to start_line == middle line, then we have narrowed the search to a small window, but it
          # is possible to for the middle to equal the start when there are several lines after middle and hence
          # it returns too early. Therefore scan any remaining lines between middle and end looking for the first
          # one with a bigger dtm and then return the line just before it.
          #
          # It may even be more efficient to just scan forwards when end - start <= 0.5MB or so, as it would involve
          # less seeks.
          read_lines_from_position(-1, middle_line.start_file_position) { |l|
            if l.timestamp > dtm
              break
            else
              return_line = l
            end
          }
          return return_line
        end

        if dtm <= middle_line.timestamp
          search_for_time_internal(dtm, start_line, middle_line)
        else
          search_for_time_internal(dtm, middle_line, end_line)
        end
      end

    end
  end
end
