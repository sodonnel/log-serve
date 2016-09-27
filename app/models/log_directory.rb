module LogServe
  module Models
    class LogDirectory

      def initialize(path)
        @path = path
        @files = Hash.new
      end

      # Find all the log files, ignoring the index files
      # Would like to mark merged files somehow ...
      def load_files
        files = Dir.entries(@path).select {|f| !File.directory? f}.select {|f| f !=~ /(\.gz|\.zip|\.logserveidx)$/}
        files.each do |f|
          lf = LogFile.new(File.join(@path, f))
          @files[lf.key] = lf
        end
        self
      end

      def find_file(key)
        @files[key]
      end

      def each
        @files.keys.each do |k|
          yield @files[k]
        end
      end
      
    end
  end
end