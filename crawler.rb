require 'mechanize'
require './story'

class Crawler
  YUKARIN_URL = 'http://www.tamurayukari.com'

  def initialize
    @mechanize = Mechanize.new
  end

  def logger=(logger)
    @logger = logger
  end

  def elements
    begin
      page = @mechanize.get(YUKARIN_URL)
    rescue
      @logger.error $! unless @logger.nil?
    end
    page.nil? ? [] : page.search('#news_table tr')
  end

  def stories
    results = elements.map do |element|
      titles = element.search('th').map do |dt|
        dt.content
      end

      contents = element.search('a').map do |a|
        {value: a.content, url: a.attribute('href').value}
      end

      titles.zip(contents).map do |title, content|
        Story.new(title, content[:value], content[:url])
      end
    end
    results.flatten.reverse
  end
end
