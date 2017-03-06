require 'json'
require 'nokogiri'
require 'open-uri'
require 'cgi'
require 'json'
require 'pry'
require 'requestmanager'
require 'headless'

load 'crawlers/securityclearedjobscom/security_cleared_jobs_com_parser.rb'
load 'crawlers/util/failure_handler.rb'

class SecurityClearedJobsComCrawler
  include FailureHandler
  def initialize(search_term, requests=nil, cm_hash=nil)
    @search_term = search_term
    @requests = requests
    @site_url = "https://www.securityclearedjobs.com"
    @query_base_url = set_base_url
    @output = Array.new

    # Handle crawler manager info
    @cm_url = cm_hash[:crawler_manager_url] if cm_hash
    @selector_id = cm_hash[:selector_id] if cm_hash
  end

  # Set the base url for the query
  def set_base_url
    if @search_term == nil
      return @site_url+"/searchjobs/?countrycode=GB"
    else
      return @site_url+"/searchjobs/?countrycode=GB&Keywords="+CGI.escape(@search_term)
    end
  end

  # Get the page
  def get_page(url)
    get_retry(url, @requests, 0)
  end

  # Get the total pagecount
  def get_total_pagecount
    initial_page = Nokogiri::HTML.parse(load_next_page(1))
    last_page_link = initial_page.css(".paginator__item").last.css("a")[0]['href']

    # Handle case of there just being one page
    page_count = last_page_link.split("&Page=")[1].to_i
    page_count == 0 ? (return 1) : (return page_count)
  end

  # Load the next page
  def load_next_page(page_num)
    next_page_url = @query_base_url + "&Page="+page_num.to_s
    return get_page(next_page_url)
  end

  # Save the result links on a page
  def save_result_links(page)
    html = Nokogiri::HTML.parse(page)
    return html.css(".lister__header").css("a").map{|e| @site_url+e['href']}
  end

  # Parse all the listings on a single page
  def parse_listings(page)
    listing_links = save_result_links(page)
    found_listings = Array.new
    
    listing_links.each do |listing|
      parser = SecurityClearedJobsComParser.new(listing, get_page(listing), @requests)
      parsed_listing = parser.parse
      found_listings.push(parsed_listing) if parsed_listing
    end
    
    report_results(found_listings, listing_links.first)
  end

  # Crawls all of the listings
  def crawl
    total_pagecount = get_total_pagecount
    
    # Load each page
    (1..total_pagecount).each do |page_num|
      next_page = load_next_page(page_num)
      parse_listings(next_page)
    end
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

  # Output JSON
  def gen_json
    return JSON.pretty_generate(@output)
  end
end


Headless.ly do
  r = RequestManager.new(nil, [0, 0], 1)
  c = SecurityClearedJobsComCrawler.new(nil, r)
  c.crawl
  File.write("securityclearedjobscom_data.json", c.gen_json)
end
