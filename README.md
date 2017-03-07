This is a crawler for job listings that require security clearance.

To run-

t = TSJobCrawler.new("search term" (or nil), request_manager, cm_hash or nil)
t.crawl_jobs


For example-

Headless.ly do
  r = RequestManager.new(nil, [0, 0], 1)
  t = TSJobCrawler.new(nil, r, nil)
  t.crawl_jobs
  File.write("test.json", t.gen_json)
end


If you input nil for the search term, it downloads as many job listings as
possible. Unless you have a lot of RAM, you should run it through Harvester if
you want to download as many listings as possible as then you can take
advantage of incremental result reporting.
