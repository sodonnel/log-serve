module LogServe
  module Routes
    class Viewer < Sinatra::Application

      set :views, File.expand_path('../../views', __FILE__)

      before '/file/:filekey/*' do 
        @log_file = $log_directory.find_file(params[:filekey])
      end


      get '/viewer/:filekey/?:position?' do
        log_position = params['position'].to_i || 0
        erb :viewer, :locals => { :position => log_position, :filekey => params['filekey'] }
      end

      get '/file/:filekey/more/?:position?' do
        log_position = params['position'].to_i || 0
        lines = @log_file.read_lines_from_position($lines_per_request, log_position)
        
        erb :more, :layout => false, :locals => { :lines => lines,
                                                  :max_lines => $lines_maintained_in_viewer,
                                                  :log_position => @log_file.last_io_position.to_s,
                                                  :no_more_messages => @log_file.eof? }
      end

      get '/file/:filekey/position/end' do
        new_position = @log_file.eof_position
        erb :reset, :layout => false, :locals => { :eof => true, :position => new_position }
      end

      get '/file/:filekey/less/?:position?' do
          log_position = params['position'].to_i || 0
          lines = @log_file.read_lines_backwards_from_position($lines_per_request, log_position).reverse
                    
          erb :previouslines, :layout => false, :locals => { :lines => lines,
                                                             :max_lines => $lines_maintained_in_viewer,
                                                             :log_position => @log_file.last_io_position.to_s,
                                                             :no_more_messages => @log_file.eof? }
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
