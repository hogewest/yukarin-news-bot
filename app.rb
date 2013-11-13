require 'sinatra'
require 'eventmachine'
require 'redis'
require 'twitter'
require 'time'
require 'logger'
require './story'
require './crawler'

Log = Logger.new(STDOUT)
POST_TIME_KEY = 'POST_TIME'

configure :production do
  require 'newrelic_rpm'
end

uri = URI.parse(ENV['REDISTOGO_URL'] || 'localhost:6379')
REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

INTERVAL = 60 * 60 * 2
if (REDIS.exists(POST_TIME_KEY))
  post_time = Time.parse(REDIS.get(POST_TIME_KEY))
else
  post_time = Time.now + INTERVAL
  REDIS.set(POST_TIME_KEY, post_time.strftime('%Y/%m/%d %X'))
end

Twitter.configure do |config|
  config.consumer_key = ENV['TWITTER_CONSUMER_KEY'] || 'YOUR_CONSUMER_KEY'
  config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET'] || 'YOUR_CONSUMER_SECRET'
  config.oauth_token = ENV['TWITTER_OAUTH_TOKEN'] || 'YOUR_OAUTH_TOKEN'
  config.oauth_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET'] || 'YOUR_OAUTH_TOKEN_SECRET'
end

get '/' do
  "next #{post_time.strftime('%Y/%m/%d %X')}"
end

EM::defer do
  crawler = Crawler.new
  loop do
    sleep(5)
    if post_time < Time.now
      stories = crawler.elements.map do |element|
        title = element.search('dt').first.content
        content = element.search('a').first.content
        url = element.search('a').first.attribute('href').value
        Story.new(title, content, url)
      end
      stories.reverse.each do |story|
        if (!REDIS.exists(story.key))
          REDIS.set(story.key, story.to_json)
          Log.info story.key + ':' + story.tweet
          Twitter.update(story.tweet)
        else
          Log.info "exists key:" + story.key
        end
      end

      post_time = Time.now + INTERVAL
      REDIS.set(POST_TIME_KEY, post_time.strftime('%Y/%m/%d %X'))
    end
  end
end
