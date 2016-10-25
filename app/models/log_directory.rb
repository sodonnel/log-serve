module LogServe
  module Models
    class LogDirectory

      attr_reader :path

      def initialize(path)
        @path = path
        @files = Hash.new
      end

      # Find all the log files, ignoring the index files
      # Would like to mark merged files somehow ...
      def load_files
        files = Dir.entries(@path).select {|f| !File.directory? f}.select {|f| f !=~ /(\.gz|\.zip|\.logserveidx)$/}
        files.each do |f|
          add_file(f)
        end
        self
      end

      def add_file(f)
        lf = LogFile.new(File.join(@path, f))
        @files[lf.key] = lf
      end

      # LogFile is not thread safe, so instead of returning the only copy
      # of it, this method returns a clone that is intended to be used
      # by a request thread and then thrown away.
      def find_file(key)
        @files[key].clone
      end

      def each
        @files.keys.each do |k|
          yield @files[k]
        end
      end
      
    end
  end
end
