require 'mechanize'
require './story'

class Crawler
  YUKARIN_URL = 'https://www.tamurayukari.com'

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
    page.nil? ? [] : page.search('.list')
  end

  def stories
    results = elements.map do |element|
      titles = element.search('time').map do |e|
        e.content
      end

      contents = element.search('a').map do |e|
        {value: e.search('h3').first.content, url: e.attribute('href').value}
      end

      titles.zip(contents).map do |title, content|
        Story.new(title, content[:value], content[:url])
      end
    end
    results.flatten.reverse
  end
end
