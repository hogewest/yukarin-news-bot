require 'sinatra'
require 'eventmachine'
require 'redis'
require 'twitter'
require './story'
require './crawler'
require 'logger'

configure :production do
  require "newrelic_rpm"
end

Log = Logger.new(STDOUT)

INTERVAL = 60 * 60 * 4
post_time = Time.now + INTERVAL

uri = URI.parse(ENV['REDISTOGO_URL'] || 'localhost:6379')
REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

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
    sleep(1)
    if post_time < Time.now
      stories = crawler.elements.map do |element|
        title = element.search('dt').first.content
        content = element.search('dd').first.content
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
    end
  end
end
