require ~'app1_deligate'

class App1 < Sinatra::Base

  set :views, ~'/views'
  #set :public, ~'/public'
  #set :root, ~''
  #set :static, true

  get '/' do
    "Hello from app1"
  end
end
