module LogServe
  module Routes
    class Picker < Sinatra::Application

      set :views, File.expand_path('../../views', __FILE__)

      get '/picker' do
        erb :picker, :locals => { :directory => $log_directory }
      end

      get '/picker/merge' do
        # Generate a form to allow aliases to be entered and upon submit it
        # will do the actual merge
        file_keys = params['files']
        files = []
        file_keys.each {|k| files.push $log_directory.find_file(k) }
        erb :merge, :locals => { :files => files  }
      end

      
      # TODO - validate all aliases exist
      # TODO - validate that the merged filename is a plain name with no paths so it is always stored in the proper directory
      # TODO - on sumbit, block the form from being submitted again and post a message "this may take a while"
      #
      # Actually merge the files, then redirect back to the picker
      post '/picker/domerge' do
        file_keys = params['files']
        aliases   = params['aliases']
        merged_filename = params['merged_filename']

        # Create a hash with the filepath as the key and
        # the value as the alias to pass to the merge method
        file_paths_with_alias = Hash.new
        file_keys.each_with_index do |k,i|
          file_paths_with_alias[$log_directory.find_file(k).file_path] = aliases[i]
        end
        LogServe::Models::LogFileMerger.merge_files(file_paths_with_alias, File.join($log_directory.path, merged_filename))
        $log_directory.add_file(merged_filename)

        redirect to("/picker")
      end
      
    end
  end
end
