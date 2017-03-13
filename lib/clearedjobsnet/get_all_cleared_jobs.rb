require 'json'
require 'headless'
require 'requestmanager'
load 'clearedjobsnet/cleared_jobs_net_crawler.rb'

# Get as many jobs as possible
class GetAllClearedJobs
  def initialize(requests, cm_hash)
    @output = Array.new
    @requests = requests
    @cm_hash = cm_hash
  end

  # Crawl through many options
  def crawl
   get_first_1000
   get_by_clearance
   get_by_country
   get_by_company
   get_by_searchterm
  end

  # Get the most recent jobs from blank search
  def get_first_1000
    start_crawler("all")
  end

  # Crawl by security clearance
  def get_by_clearance
    clearance_levels = JSON.parse(File.read("clearedjobsnet/terms/clearance_levels.json"))
    crawl_each(clearance_levels, "security_clearance")
  end

  # Crawl each country
  def get_by_country
    country_names = JSON.parse(File.read("clearedjobsnet/terms/country_names.json"))
    crawl_each(country_names, "country")
  end

  # Crawl company pages
  def get_by_company
    company_names = JSON.parse(File.read("clearedjobsnet/terms/company_names.json"))
    crawl_each(company_names, "company_page")
  end

  # Crawl search term list
  def get_by_searchterm
    search_terms = JSON.parse(File.read("clearedjobsnet/terms/search_terms.json"))
    crawl_each(search_terms)
  end

  
  # Crawl each item
  def crawl_each(term_list, filter_name=nil)
    term_list.each do |term|
      start_crawler(term, filter_name)
    end
  end

  # Start the crawler
  def start_crawler(search_term, filter=nil)
    c = ClearedJobsNetCrawler.new(search_term, filter, @requests, @cm_hash)
    c.crawl_listings
    save_listings(c.gen_json)
  end

  # Save unique listings in output
  def save_listings(listings)
    @output = @output | JSON.parse(listings)
  end

  # Generates output JSON
  def gen_json
    return JSON.pretty_generate(@output)
  end
end

