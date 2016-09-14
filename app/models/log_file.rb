module LogServe
  module Models
    class LogFile

      attr_reader :last_io_position

      def initialize(file_path, index)
        @file_path = file_path
        @index     = index
        @fh        = File.open(@file_path, 'r')
        @lr        = LogMerge::LogReader.new(@fh)
        @lr.index  = index
      end

      def read_lines_from_position(num_to_read, pos)
        @fh.seek(pos, IO::SEEK_SET)
        @eof = false
        lines = []
        1.upto(350) do |i|
          line = @lr.next
          if line
            lines.push line
          else
            @eof = true
            break
          end
        end
        # This is the position in the file that is the last
        # character of the last line read
        @last_io_position = @lr.io_position
        lines
      end

      def eof?
        @eof
      end

      def close
        @fh.close
        @index = nil
        @lr    = nil
      end
      
    end
  end
end
