require 'json'
load 'securityclearedjobscom/security_cleared_jobs_com_crawler.rb'

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
    security_cleared_jobs_com
  end

  def security_cleared_jobs_com
    c = SecurityClearedJobsComCrawler.new(@search_term, @requests, @cm_hash)
    c.crawl
    @output += JSON.parse(c.gen_json) if @cm_hash == nil
  end

  # Generate output
  def gen_json
    JSON.pretty_generate(@output)
  end

  # Call security cleared jobs
    # Write call
    # Remove hardcoded call
    # Update paths

  # Call clearedjobs.net
    # Determine if it should be called directly or through get all
    # Update get_all to not save in JSON when called from Harvester
    # Remove hardcoded and update paths

  # Call clearancejobs.cm
    # Write call
    # Remove hardcoded and update paths
  
  # All:
    # Collect JSONS here/maybe write to disk
end

Headless.ly do
  t = TSJobCrawler.new("ruby", nil, nil)
  t.crawl_jobs
  t.gen_json
#  r = RequestManager.new(nil, [0, 0], 1)
#  c = SecurityClearedJobsComCrawler.new("ruby", nil, nil)
#  c.crawl
#  File.write("securityclearedjobscom_test.json", c.gen_json)
end
