require 'digest'

module LogServe
  module Models
    class LogFile

      attr_reader :key, :last_io_position

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
        begin
          open
          @lr.skip_to_time(dtm)
          position = @lr.io_position
          # Return nil if we are past EOF
          # or position otherwise
          @lr.next.nil? ? nil : position
        ensure
          close
        end
      end

      def eof?
        @eof
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
      
    end
  end
end
