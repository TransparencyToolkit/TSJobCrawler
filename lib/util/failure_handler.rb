require 'requestmanager'
require 'nokogiri'
require 'open-uri'

module FailureHandler
  def get_retry(url, requests, i=0)
    puts "crawling "+url
    begin
      if requests
        return requests.get_page(url)
      else
        return File.read(open(url.gsub("[", "%5B").gsub("]", "%5D")))
      end
    rescue
      if i < 10
        i+=1
        sleep(i*rand(1..10))
        get_retry(url, requests, i)
      end
    end
  end
end
