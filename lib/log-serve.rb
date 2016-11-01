require 'log-merge'

require 'rubygems'
require 'sinatra/base'

require_relative 'log-serve/helpers/global'

require_relative 'log-serve/routes/picker'
require_relative 'log-serve/routes/viewer'

require_relative 'log-serve/models/log_file'
require_relative 'log-serve/models/log_file_line'
require_relative 'log-serve/models/log_directory'
require_relative 'log-serve/models/log_file_merger'

module LogServe
  
  class App < Sinatra::Application
    configure do

      set :sessions,
          :httponly => true,
          :expire_after => 31557600 # 1 year
      set :root, File.dirname(__FILE__)+"/log-serve"
    end

    use Rack::Deflater
    
    use Routes::Picker
    use Routes::Viewer

    if $run_as_production
      $log_directory = LogServe::Models::LogDirectory.new(Dir.pwd).load_files
    else
      $log_directory = LogServe::Models::LogDirectory.new('/Users/sodonnell/Desktop/logs').load_files
    end
    $lines_per_request = 250
    $lines_maintained_in_viewer = 3 * $lines_per_request
  end

end
