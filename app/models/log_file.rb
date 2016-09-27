require 'digest'

module LogServe
  module Models
    class LogFile

      attr_reader :key, :last_io_position

      def initialize(file_path)
        @file_path = file_path
        set_key
#        @index     = index
#        @lr.index  = index
      end

      def filename
        File.basename @file_path
      end

      def read_lines_from_position(num_to_read, pos)
        open
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

      # TODO - fix this open handler as it does not reopen a closed file
      #        probably @fh is not nil after it has been closed
      def open
        @fh ||= File.open(@file_path, 'r')
        @lr ||= LogMerge::LogReader.new(@fh)
      end

      def close
        if @fh
          @fh.close
        end
        @lr    = nil
      end

      private

      def set_key
        @key = Digest::MD5.hexdigest @file_path
      end
      
    end
  end
end
