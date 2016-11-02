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
                                                  :no_more_messages => @log_file.eof? }
      end

      get '/file/:filekey/position/:position' do
        new_position = params['position']
        eof_position = @log_file.eof_position
        
        if new_position == 'end'
          new_position = eof_position
        else
          new_position = new_position.to_i
        end
        new_position = eof_position if new_position > eof_position
        new_position = 0 if new_position < 0

        forward_lines = @log_file.read_lines_from_position($lines_per_request, new_position)
        read_backwards_from = forward_lines.length > 0 ? forward_lines.first.start_file_position : new_position
        
        reverse_lines = @log_file.read_lines_backwards_from_position($lines_per_request,
                                                                     read_backwards_from).reverse
        
        lines = reverse_lines + forward_lines

        erb :viewer_position, :layout => false, :locals => { :lines => lines,
                                                             :max_lines => $lines_maintained_in_viewer,
                                                             :requested_position => new_position }
        
#        erb :reset, :layout => false, :locals => { :eof => true, :position => new_position }
      end

      get '/file/:filekey/less/?:position?' do
          log_position = params['position'].to_i || 0
          lines = @log_file.read_lines_backwards_from_position($lines_per_request, log_position).reverse
                    
          erb :previouslines, :layout => false, :locals => { :lines => lines,
                                                             :max_lines => $lines_maintained_in_viewer,
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
