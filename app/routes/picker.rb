module LogServe
  module Routes
    class Picker < Sinatra::Application

      set :views, 'app/views'

      get '/picker' do
        erb :picker
      end
      
    end
  end
end
