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
          # I don't think the condition on end_line is necessary. The algorithm should converge to two lines and then the middle
          # will generally fallback to the start line, which should be the line before the time you are asking for.
          return middle_line
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
