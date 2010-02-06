require 'rack'
require 'sinatra'
require 'haml'
require 'dirge' # see http://github.com/joshbuddy/dirge/

# replace this require with require 'watch-tower' in your code
require ::File.join(::File.dirname(__FILE__),'../lib/watch-tower.rb')

# our app files
require ~'app1/app1'
require ~'app1/app1_deligate'
require ~'app2/app2'
require ~'login_handler/login_handler'

use Rack::Session::Pool, :expire_after => 60 * 30 # 30 minute timeout on sessons

use SoldierOfCode::TowerGate, { '/app1/'=>App1Deligate,
                                '/app2/'=>App2}

map '/app2/' do
  run App2
end

map '/app1/' do
  run App1
end

map '/' do
  run LoginHandler
end
