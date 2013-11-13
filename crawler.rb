require 'mechanize'

class Crawler
  YUKARIN_URL = 'http://tamurayukari.com'

  def initialize
    @mechanize = Mechanize.new
  end

  def elements
    begin
      page = @mechanize.get(YUKARIN_URL)
    rescue Mechanize::ResponseCodeError => e
      puts e
    end
    return [] if page.nil?
    page.search('#news > dl')
  end
end
