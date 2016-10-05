module LogServe
  module Models
    class LogFileLine

      attr_reader :log_line, :start_read_position, :end_read_position

      def initialize(log_line, start_position, end_position)
        @log_line            = log_line
        @start_read_position = start_position
        @end_read_position   = end_position
      end

      # Proxy methods to the LogMerge::LogLine class

      def content
        @log_line.content
      end

      def raw_content
        @log_line.raw_content
      end

      
      def log_alias
        @log_line.log_alias
      end

      def level
        @log_line.level
      end

      def timestamp
        @log_line.timestamp
      end

    end
  end
end
