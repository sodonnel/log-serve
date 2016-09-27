module LogServe
  module Routes
    class Viewer < Sinatra::Application

#      $logfiles = LogServe::Models::LogDirectory.new('/Users/sodonnell/Desktop/logs')

        # '/Users/sodonnell/Desktop/logs/hadoop-cmf-hdfs01-FAILOVERCONTROLLER-frafatahdpappb1.de.db.com.log.out'
      $logfile_index = nil
      # TODO - alias color picker
      $alias_color_picker = ColorPicker.new
      
      set :views, 'app/views'

      get '/viewer/:filekey/?' do
        erb :viewer, :locals => { :filekey => params['filekey'] }
      end

      get '/loglines/:filekey/?:position?' do
        begin
          log_position = params['position'].to_i || 0
          log_file = $log_directory.find_file(params[:filekey]) #logServe::Models::LogFile.new($logfile, $logfile_index)
          lines = log_file.read_lines_from_position(350, log_position)
                    
          erb :more, :layout => false, :locals => { :lines => lines, :log_position => log_file.last_io_position.to_s, :no_more_messages => log_file.eof? }
        ensure
          #log_file.close
        end
      end

      helpers LogServe::Helpers
    end

  end
end