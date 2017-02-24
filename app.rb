require 'sinatra'
require 'redis'
require 'sprockets'
require 'haml'

class Focaccia < Sinatra::Base
  FOCACCIA_URL = 'https://www.focacciacatering.com'

  redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379')

  set :environment, Sprockets::Environment.new

  environment.append_path "assets/stylesheets"

  # Sprockets assets routes
  get "/assets/*" do
    env["PATH_INFO"].sub!("/assets", "")
    settings.environment.call(env)
  end

  get '/' do
    haml :index
  end

  get '/leaderboard' do
    @leaderboard = redis.keys('focaccia:victim_count:*').map do |key|
      name = key.match(/focaccia:victim_count:([a-zA-Z]+)/)[1]
      { name: name, count: redis.get(key) }
    end
    @leaderboard.sort! {|a,b| -1 * (a[:count] <=> b[:count]) }

    haml :leaderboard
  end

  post '/cacc' do
    if params[:name]
      redis_key = 'focaccia:victim_count:' + params[:name]

      if redis.exists(redis_key)
        redis.incr(redis_key)
      else
        redis.set(redis_key, 1)
      end
    end
    redirect FOCACCIA_URL
  end
end
