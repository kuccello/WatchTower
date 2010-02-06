class App1Deligate
  include SoldierOfCode::SentryDeligate

  def login_uri
    '/login'
  end

  def logout_uri
    '/logout'
  end

  def token_keys
    [:app1,:default]
  end

  def dethenticate(env)
    env['rack.session'][:app1] = nil
  end

  def authenticate(usr_id, pass)
    # You would perform what ever authentication you wanted to here or deligate to another object
    return :app1, "yes"
  end
end
