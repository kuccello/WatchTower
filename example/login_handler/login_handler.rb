=begin
  This is an example of a login handler
=end
class LoginHandler < Sinatra::Base

  set :views, ~'/views'

  get '/' do
    haml :index
  end

  get '/login' do
    return_path = session['watchtower.return_path'] ? session['watchtower.return_path'] : "/login"
    haml :login, :locals=>{:submit_to=>return_path}
  end

  post '/login' do
    if params[:email] == "foo@example.com" && params[:password] == "abc123" then
      session[:default] = params[:email]
      redirect '/app2/'
    else
      redirect '/login'
    end
  end

  get '/logout' do
    session[:default]=nil
    redirect '/login'
  end

end
