require 'sinatra'
require 'eventmachine'
require 'redis'
require 'twitter'
require 'time'
require 'logger'
require './crawler'

configure :production do
  require 'newrelic_rpm'
end

LOG = Logger.new(STDOUT)
LOG.level = Logger.const_get ENV['LOG_LEVEL'] || 'DEBUG'

Redis.exists_returns_integer = true
REDIS_URI = URI.parse(ENV['REDIS_URL'] || 'localhost:6379')
REDIS = Redis.new(:host => REDIS_URI.host, :port => REDIS_URI.port, :password => REDIS_URI.password)

POST_TIME_KEY = 'POST_TIME'
INTERVAL = 60 * 60 * 2

if (REDIS.exists(POST_TIME_KEY) > 0)
  post_time = Time.parse(REDIS.get(POST_TIME_KEY))
else
  post_time = Time.now + INTERVAL
  REDIS.set(POST_TIME_KEY, post_time.strftime('%Y/%m/%d %X'))
end

TWITTER = Twitter::REST::Client.new do |config|
  config.consumer_key = ENV['TWITTER_CONSUMER_KEY'] || 'YOUR_CONSUMER_KEY'
  config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET'] || 'YOUR_CONSUMER_SECRET'
  config.access_token = ENV['TWITTER_OAUTH_TOKEN'] || 'YOUR_OAUTH_TOKEN'
  config.access_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET'] || 'YOUR_OAUTH_TOKEN_SECRET'
end

get '/' do
  "next #{post_time.strftime('%Y/%m/%d %X')}"
end

EM::defer do
  crawler = Crawler.new
  crawler.logger = LOG

  loop do
    if post_time < Time.now
      crawler.stories.each do |story|
        if (REDIS.exists(story.key) > 0)
          LOG.info("exists key:#{story.key}")
        else
          LOG.info("#{story.key}:#{story.tweet}")
          REDIS.set(story.key, story.to_json)
          begin
            TWITTER.update(story.tweet)
            sleep(5)
          rescue
            LOG.error("error story:" + story.to_json)
            LOG.error($!)
          end
        end
      end
      post_time = Time.now + INTERVAL
      REDIS.set(POST_TIME_KEY, post_time.strftime('%Y/%m/%d %X'))
    end

    sleep(5)
  end
end
