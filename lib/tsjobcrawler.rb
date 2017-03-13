require 'json'
load 'securityclearedjobscom/security_cleared_jobs_com_crawler.rb'
load 'clearancejobscom/clearance_jobs_com_crawler.rb'
load 'clearedjobsnet/cleared_jobs_net_crawler.rb'
load 'clearedjobsnet/get_all_cleared_jobs.rb'

# Crawls all the jobs that require clearance
class TSJobCrawler
  def initialize(search_term, requests=nil, cm_hash=nil)
    @search_term = search_term
    @requests = requests
    @cm_hash = cm_hash
    @output = Array.new
  end

  # Crawl all of the listing sites
  def crawl_jobs
    cleared_jobs_net
    clearance_jobs_com
    security_cleared_jobs_com
  end

  def security_cleared_jobs_com
    c = SecurityClearedJobsComCrawler.new(@search_term, @requests, @cm_hash)
    c.crawl
    @output += JSON.parse(c.gen_json) if @cm_hash == nil
  end

  def clearance_jobs_com
    c = ClearanceJobsComCrawler.new(@search_term, @requests, @cm_hash)
    c.crawl
    @output += JSON.parse(c.gen_json) if @cm_hash == nil
  end

  def cleared_jobs_net
    if @search_term == nil
      g = GetAllClearedJobs.new(@requests, @cm_hash)
      g.crawl
      @output += JSON.parse(g.gen_json) if @cm_hash == nil
    else # Scrape by search term
      c = ClearedJobsNetCrawler.new(@search_term, nil, @requests, @cm_hash)
      c.crawl_listings
      @output += JSON.parse(c.gen_json) if @cm_hash == nil
    end
  end

  # Generate output
  def gen_json
    JSON.pretty_generate(@output)
  end
end

