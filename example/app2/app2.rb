class App2 < Sinatra::Base
  include SoldierOfCode::SentryDeligate

  def login_uri
    '/login'
  end

  def token_keys
    [:app2,:default]
  end

  def authenticate(usr_id, pass)
    # You would perform what ever authentication you wanted to here or deligate to another object
    return :app2, "yes"
  end

  set :views, ~'/views'

  get '/' do
    "Hello from app2"
  end
end
