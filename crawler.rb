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
    page.nil? ? [] : page.search('#news > dl')
  end

  def stories
    results = elements.map do |element|
      title = element.search('dt').first.content

      element.search('a').map do |a|
        content = a.content
        url = a.attribute('href').value
        Story.new(title, content, url)
      end
    end
    results.flatten.reverse
  end
end
