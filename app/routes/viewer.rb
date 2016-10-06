module LogServe
  module Routes
    class Viewer < Sinatra::Application

#      $logfiles = LogServe::Models::LogDirectory.new('/Users/sodonnell/Desktop/logs')

        # '/Users/sodonnell/Desktop/logs/hadoop-cmf-hdfs01-FAILOVERCONTROLLER-frafatahdpappb1.de.db.com.log.out'
      $logfile_index = nil
      # TODO - alias color picker
      $alias_color_picker = ColorPicker.new
      
      set :views, 'app/views'

      get '/viewer/:filekey/?:position?' do
        log_position = params['position'].to_i || 0
        erb :viewer, :locals => { :position => log_position, :filekey => params['filekey'] }
      end

      get '/loglines/:filekey/?:position?' do
        begin
          log_position = params['position'].to_i || 0
          log_file = $log_directory.find_file(params[:filekey]) #logServe::Models::LogFile.new($logfile, $logfile_index)
          lines = log_file.read_lines_from_position(100, log_position)
                    
          erb :more, :layout => false, :locals => { :lines => lines, :log_position => log_file.last_io_position.to_s, :no_more_messages => log_file.eof? }
        ensure
          log_file.close
        end
      end

      get '/viewer/previouslines/:filekey/?:position?' do
          log_position = params['position'].to_i || 0
          log_file = $log_directory.find_file(params[:filekey])
          lines = log_file.read_lines_backwards_from_position(100, log_position).reverse
                    
          erb :previouslines, :layout => false, :locals => { :lines => lines, :log_position => log_file.last_io_position.to_s, :no_more_messages => log_file.eof? }
      end

      post '/gotodate/:filekey' do
        begin
          date_string = params['datetime']
          warn date_string
          log_file = $log_directory.find_file(params[:filekey])

          dtm = DateTime.strptime(date_string, "%Y-%m-%d %H:%M:%S")
          new_position = log_file.position_at_time(dtm)
          warn new_position
          #  pp $logfile_index.get_index_hash

          erb :gotodate, :layout => false, :locals => { :new_position => new_position }
        end
      end

      helpers LogServe::Helpers
    end

  end
end
