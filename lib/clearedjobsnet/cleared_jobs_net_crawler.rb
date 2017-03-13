require 'nokogiri'
require 'open-uri'
require 'cgi'
require 'json'
require 'requestmanager'
require 'harvesterreporter'

load 'clearedjobsnet/cleared_jobs_net_parser.rb'
load 'util/failure_handler.rb'

class ClearedJobsNetCrawler
  include FailureHandler
  def initialize(crawl_type, filter_name=nil, requests=nil, cm_hash=nil)
    @base_url = "https://clearedjobs.net/"
    @output = Array.new
    @requests = requests

    # Handle crawler manager info
    @reporter = HarvesterReporter.new(cm_hash)
    
    # Get all items
    if crawl_type == "all"
      @crawl_type = crawl_type

    # Get a company page
    elsif filter_name == "company_page"
      @crawl_type = "company_page"
      @search_term = crawl_type

    # Add a filter
    elsif filter_name
      @crawl_type = "filter"
      @filter = filter_name
      @search_term = crawl_type

    # Query search
    else
      @crawl_type = "search"
      @search_term = crawl_type
    end
  end

  # Crawls the listings for the query
  def crawl_listings
    pages_to_crawl = get_num_pages_per_query.to_i
    base_url = get_base_query_url
    
    # Loop through pages and collect links for each
    (1..pages_to_crawl).each do |page_num|
      next_page_html = goto_next_page(base_url, page_num)
      collect_page_links(next_page_html)
    end
  end

  # Collect all the links on the page
  def collect_page_links(page_html)
    html = Nokogiri::HTML.parse(page_html)
    result_rows = html.css("table.search_res").css("tbody").css("tr")
    
    # Parse URL and date from each row
    parsed_result_rows = result_rows.map do |r|
      link = (@base_url+r.css("a")[0]['href']).split("/keywords")[0]
      date = Date.parse(r.css("div").select{|e| e.text.include?("Posted - ")}.first.text.gsub("Posted - ", ""))
      {url: link, posting_date: date}
    end
    
    parse_all_listings(parsed_result_rows)
    return parsed_result_rows
  end

  # Parse all of the listings
  def parse_all_listings(listing_links)
    found_listings = Array.new
    listing_links.each do |listing|
      parser = ClearedJobsNetParser.new(get_page(listing[:url]), listing, @requests)
      found_listings.push(parser.parse_job)
    end

    @reporter.report_results(found_listings, listing_links.first[:url])
  end

  # Gets the number of pages for the query
  def get_num_pages_per_query
    # Go to the last page
    html = Nokogiri::HTML.parse(run_initial_query)
    if !html.css("div.navbar_bottom").css("a").empty?
      last_page_link = @base_url+html.css("div.navbar_bottom").css("a").last['href']
      last_page_html = Nokogiri::HTML.parse(get_page(last_page_link.gsub("//", "/")))
     
      # Parse the page numbers in last page
      return last_page_html.css("div.navbar_bottom").css("strong").text
    else # Just one page of results
      return "1"
    end
  end

  # Goes to the next page
  def goto_next_page(base_query_url, num)
    start_index = (num-1)*25

    # Set the URL for the next page appropriately
    if start_index == 0 || num == 0
      next_page_url = base_query_url
    else
      next_page_url = base_query_url+"/start/"+start_index.to_s
    end
    
    return get_page(next_page_url)
  end

  # Open the page
  def get_page(url, i=0)
    get_retry(url, @requests, 0)
  end

  # Get the initial results page
  def run_initial_query
    url = get_base_query_url
    return get_page(url)
  end

  # Get the base query url depending on type
  def get_base_query_url
    if @crawl_type == "all"
      return @base_url+"search/action/advanced_search/zip_radius/20/keywords/+/city_state_zip/+/security_clearance/+/submit/SEARCH+JOBS/sort/time"
    elsif @crawl_type == "search"
      encoded_term = CGI.escape(@search_term)
      return @base_url+"search/action/advanced_search/zip_radius/20/keywords/"+encoded_term+"/city_state_zip/+/security_clearance/+/submit/SEARCH+JOBS"
    elsif @crawl_type == "filter"
      encoded_term = CGI.escape(@search_term)
      return @base_url+"search/action/advanced_search/keywords/+/"+@filter+"[]/"+encoded_term+"/zip/+/zip_radius/20"
    elsif @crawl_type == "company_page"
      return @base_url+"view-employer/employer_id_seo/"+@search_term
    end
  end

  # Return JSON
  def gen_json
    return @reporter.gen_json
  end
end
