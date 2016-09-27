module LogServe
  module Routes
    class Picker < Sinatra::Application

      set :views, 'app/views'

      get '/picker' do
        erb :picker, :locals => { :directory => $log_directory }
      end
      
    end
  end
end
