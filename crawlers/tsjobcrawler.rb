# Crawls all the jobs that require clearance
class TSJobCrawler
  def initialize(search_term, requests=nil, cm_hash=nil)
    @search_term = search_term
    @requests = requests
    @cm_hash = cm_hash
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
    # Collect JSONS here
end
