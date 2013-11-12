require 'digest/md5'
require 'json'

class Story
  attr_accessor :title, :content, :url
  MAX_TWEET_SIZE = 140

  def initialize(title, content, url)
    @title = title
    @content = content
    @url = url
  end

  def key
    Digest::MD5.hexdigest(title + content + url)
  end

  def tweet
    msg = "#{title} #{content} #{url}"
    return msg if msg.length <= MAX_TWEET_SIZE

    over_size = msg.length - MAX_TWEET_SIZE
    msg = "#{title} #{content} "
    msg.slice(0...(msg.length - over_size - 1)) + " #{url}"
  end

  def to_json
    hash = {}
    hash[:title] = title
    hash[:content] = content
    hash[:url] = url
    hash.to_json
  end
end
