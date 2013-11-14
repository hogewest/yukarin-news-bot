require 'sinatra'
require 'eventmachine'
require 'redis'
require 'twitter'
require 'time'
require 'logger'
require './story'
require './crawler'

configure :production do
  require 'newrelic_rpm'
end

$logger = Logger.new(STDOUT)
$logger.level = Logger.const_get ENV['LOG_LEVEL'] || 'DEBUG'
POST_TIME_KEY = 'POST_TIME'

uri = URI.parse(ENV['REDISTOGO_URL'] || 'localhost:6379')
$cache = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

INTERVAL = 60 * 60 * 2
if ($cache.exists(POST_TIME_KEY))
  post_time = Time.parse($cache.get(POST_TIME_KEY))
else
  post_time = Time.now + INTERVAL
  $cache.set(POST_TIME_KEY, post_time.strftime('%Y/%m/%d %X'))
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
    if post_time < Time.now
      stories = crawler.elements.map do |element|
        title = element.search('dt').first.content

        element.search('a').map do |a|
          content = a.content
          url = a.attribute('href').value
          Story.new(title, content, url)
        end
      end
      stories.flatten.reverse.each do |story|
        if (!$cache.exists(story.key))
          $cache.set(story.key, story.to_json)
          $logger.info story.key + ':' + story.tweet
          Twitter.update(story.tweet)
        else
          $logger.info "exists key:" + story.key
        end
      end

      post_time = Time.now + INTERVAL
      $cache.set(POST_TIME_KEY, post_time.strftime('%Y/%m/%d %X'))
    end

    sleep(5)
  end
end
