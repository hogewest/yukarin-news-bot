require "mechanize"

class Crawler
  YUKARIN_URL = "http://tamurayukari.com"
  #YUKARIN_URL = "http://localhost:9292"

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
