module LogServe
  module Models
    class LogFileMerger

      def self.merge_files(path_alias_hash, output_path)
        lm  = LogMerge::LogCombiner.new
        ofh = File.open(output_path, 'w')
        # The LogReader objects never close their file handles, so
        # this method needs to track the handles and ensure they are
        # closed.
        all_fhs = Array.new
        begin
          path_alias_hash.keys.each do |k|
            all_fhs.push File.open(k)
            lr = LogMerge::LogReader.new(all_fhs.last, path_alias_hash[k])
            lm.add_log_reader(lr)
          end
          lm.merge(ofh)
        ensure
          ofh.close
          all_fhs.each {|f| f.close }
        end
      end
      
    end
  end
end
