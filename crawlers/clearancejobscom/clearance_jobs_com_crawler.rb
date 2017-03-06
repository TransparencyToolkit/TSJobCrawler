require 'pry'
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'json'
require 'requestmanager'
require 'headless'

load 'crawlers/clearancejobscom/clearance_jobs_com_parser.rb'
load 'crawlers/util/failure_handler.rb'

class ClearanceJobsComCrawler
  include FailureHandler
  def initialize(search_term, requests=nil, cm_hash=nil)
    @search_term = search_term
    @requests = requests
    @base_url = set_base_url
    @output = Array.new

    # Handle crawler manager info
    @cm_url = cm_hash[:crawler_manager_url] if cm_hash
    @selector_id = cm_hash[:selector_id] if cm_hash
  end

  # Run the crawler
  def crawl
    page_count = get_page_count

    (1..page_count).each do |page_num|
      listing_links = collect_links_on_page(get_next_page(page_num))
      parse_listings(listing_links)
    end
  end

  # Get base url
  def set_base_url
    if @search_term == nil
      @base_url = "https://www.clearancejobs.com/jobs?"
    else
      @base_url = "https://www.clearancejobs.com/jobs?keywords="+CGI.escape(@search_term)+"&zip_text="
    end
  end

  # Get the URL for the next page
  def get_next_page_url(page_num)
    return @base_url+"PAGE="+page_num.to_s+"&limit=25"
  end

  # Get the page
  def get_page(url)
    get_retry(url, @requests, 0)
  end

  # Get the correct total # of pages
  def get_page_count
    page_html = Nokogiri::HTML.parse(get_next_page(1))
    result_count = page_html.css("#viewing").text.split(" of ")[1].gsub(",", "").to_i
    return (result_count/25.0).ceil
  end

  # Get the next page
  def get_next_page(page_num)
    return get_page(get_next_page_url(page_num))
  end

  # Collect the links on the page
  def collect_links_on_page(page)
    html = Nokogiri::HTML.parse(page)
    return html.css(".cj-search-result-item-title").css("a").map{|a| a['href']}
  end

  # Parse the listings on the page
  def parse_listings(listings)
    found_listings = Array.new
    listings.each do |listing|
      parser = ClearanceJobsComParser.new(listing, get_page(listing), @requests)
      parsed_listing = parser.parse
      found_listings.push(parsed_listing) if parsed_listing
    end

    report_results(found_listings, listings.first)
  end

  # Figure out how to report results
  def report_results(results, link)
    if @cm_url
      report_incremental(results, link)
    else
      report_batch(results)
    end
  end

  # Report all results in one JSON
  def report_batch(results)
    results.each do |result|
      @output.push(result)
    end
  end

  # Report results back to Harvester incrementally
  def report_incremental(results, link)
    curl_url = @cm_url+"/relay_results"
    c = Curl::Easy.http_post(curl_url,
                             Curl::PostField.content('selector_id', @selector_id),
                             Curl::PostField.content('status_message', "Collected " + link),
                             Curl::PostField.content('results', JSON.pretty_generate(results)))
  end

  def gen_json
    return JSON.pretty_generate(@output)
  end
end

#Headless.ly do
#  r = RequestManager.new(nil, [0, 0], 1)
#  c = ClearanceJobsComCrawler.new("osint", r)
#  c.crawl
#  File.write("clearancejobscom_test.json", c.gen_json)
#end

c = ClearanceJobsComCrawler.new(nil)
c.crawl
File.write("clearancejobscom_data.json", c.gen_json)
