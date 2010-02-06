=begin

Copyright (c) 2010 Kristan 'Krispy' Uccello <krispy@soldierofcode.com>
                                                     - Soldier Of Code

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=end
module SoldierOfCode

  module SentryDeligate

    send :define_method, :token_keys do
      [:default]
    end

    send :define_method, :valid_user_identifier? do |ident|
      %w{ email username usr nickname nick u }.each do |v|
        return true if v == ident
      end
      false
    end

    send :define_method, :valid_password_identifier? do |ident|
      %w{ password pass pwd secret }.each do |v|
        return true if v == ident
      end
      false
    end

    # dethenticate -- step out of the logged in session token
    send :define_method, :dethenticate do
      # should return a token key and token value
      throw "You need to implement the dethenticate method on #{self.class.name} which clears the session token key"
    end

    # authenticate -- perform authentication against usr/pass
    send :define_method, :authenticate do |usr_id, pass|
      # should return a token key and token value
      throw "You need to implement the authenticate(usr_id,pass) method on #{self.class.name} which returns a token key and token value if successful"
    end

    # authenticated? -- correct token(s) is present on session
    send :define_method, :authenticated? do |env|
      session = env['rack.session']
      token = nil
      (send :token_keys).each do |k|
        # check session for key
        token = session[k] if session[k]
      end
      token
    end

    # authorized? -- token key is authorized or authorization credentials are provided
    send :define_method, :authorized? do |env|
      authorized = false
      unless (send :authenticated?, env)
        req = Rack::Request.new(env)
        if req.post? then
          usr = ''
          pwd = ''
          req.params.each do |k, v|
            usr = v if usr == '' && (send :valid_user_identifier?, k)
            pwd = v if pwd == '' && (send :valid_password_identifier?, k)
          end
          token_key, token_value = (send :authenticate, usr, pwd)
          if token_key && token_value then
            session = env['rack.session']
            session[token_key] = token_value
            env['rack.session'] = session
          end
          authorized = (send :authenticated?, env)
        end
      else
        authorized = true
      end
      authorized
    end

    send :define_method, :login_uri do
      # should return a token key and token value
      throw "You need to implement the login_uri method on #{self.class.name} which returns a uri to its login view"
    end

    send :define_method, :logout_uri do
      # should return a token key and token value
      throw "You need to implement the logout_uri method on #{self.class.name} which returns a uri to its logout handler"
    end


  end

  class TowerGate
    attr_accessor :guards, :app

    def initialize(app=nil, guards={})
      @app = app
      @guards = guards
    end

    def call(env)
      session = env['rack.session']
      result = [401, {"Content-Type"=>"text/html"}, 'You have been arrested by this server.']
      begin
        guard = locate_guard(env)

        if guard then

          # "just need to check your paper work sir..."
          if guard.authenticated?(env) then
            # "looks like your cleared to enter, have a nice day"
            result = @app.call(env)
          elsif guard.authorized?(env) then
            return_path = session['watchtower.return_path']
            return_path = nil if return_path == ''

            # "looks like your cleared to enter, have a nice day"
            unless return_path then
              result = @app.call(env)
            else
              code = 302
              headers = {"Location" => return_path}
              result = [code, headers, []]
              session['watchtower.return_path'] = nil
            end
          else
            # "If you'd like to step over here sir and please remove your shoes..."
            code = 302
            headers = {"Location" => guard.login_uri}
            result = [code, headers, []]
          end
        else
          # No guard on duty - "This compound is monitored at all times" - sure...
          result = @app.call(env)
        end
      rescue => e
        puts "#{__FILE__}:#{__LINE__} [#{__method__}] EXCEPTION: #{e}"
        e.backtrace().each_with_index do |l, i|
          puts "\t- EXCEPTION STACK [#{i}]: #{l}"
        end
      end
      result
    end

    def locate_guard(env)
      guard = nil
      begin
        session = env['rack.session'] ||= {}
        path = env['REQUEST_PATH']
        @guards.each do |proto_path, deligate|
          if path.starts_with?(proto_path)
            keys = deligate.new.token_keys # I really wanted to meta code a class method but...
            token = nil
            keys.each do |k|
              # check session for key
              token = session[k] if session[k]
            end
            unless token
              session['watchtower.return_path'] = path
              env['rack.session'] = session
              guard = deligate.new
            end
          end
        end
      rescue => e
        puts "#{__FILE__}:#{__LINE__} [#{__method__}] EXCEPTION: #{e}"
        e.backtrace().each_with_index do |l, i|
          puts "\t- EXCEPTION STACK [#{i}]: #{l}"
        end
      end
      guard
    end
  end

end

class String
  def starts_with?(characters)
    self.match(/^#{characters}/) ? true : false
  end
end
