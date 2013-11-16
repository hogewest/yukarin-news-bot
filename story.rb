require 'digest/md5'
require 'json'

class Story
  attr_accessor :title, :content, :url
  MAX_TWEET_SIZE = 118 #http:118 https:117
  YUKARIN_TOP_PAGE_URL = 'http://www.tamurayukari.com/'

  def initialize(title, content, url)
    @title = title
    @content = content
    @url = url.start_with?(YUKARIN_TOP_PAGE_URL) ? url : YUKARIN_TOP_PAGE_URL + url
  end

  def key
    Digest::MD5.hexdigest(title + content + url)
  end

  def tweet
    msg = "#{content} "
    return msg + url if msg.length <= MAX_TWEET_SIZE

    over_size = msg.length - MAX_TWEET_SIZE
    msg.slice(0...(msg.length - over_size - 2)) + "… #{url}"
  end

  def to_json
    {title: title, content: content, url: url}.to_json
  end
end
