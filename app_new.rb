$:.unshift File.expand_path(File.dirname(__FILE__))
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "../log-merge", "lib"))


require 'log-merge'

require 'rubygems'
require 'sinatra/base'

require_relative 'lib/color_picker'

require_relative 'app/helpers/global'

require_relative 'app/routes/picker'
require_relative 'app/routes/viewer'

require_relative 'app/models/log_file'
require_relative 'app/models/log_file_line'
require_relative 'app/models/log_directory'
require_relative 'app/models/log_file_merger'

puts 'loaded libs'

module LogServe
  
  class App < Sinatra::Application
    configure do

      set :sessions,
          :httponly => true,
          :expire_after => 31557600 # 1 year
    end

    use Rack::Deflater
    
    use Routes::Picker
    use Routes::Viewer

    $log_directory = LogServe::Models::LogDirectory.new('/Users/sodonnell/Desktop/logs').load_files
    $lines_per_request = 250
    $lines_maintained_in_viewer = 3 * $lines_per_request
  end

end
