require 'pry'
load 'lib/clearedjobsnet/cleared_jobs_net_crawler.rb'
load 'lib/clearedjobsnet/cleared_jobs_net_parser.rb'

RSpec.describe ClearedJobsNetCrawler do
  describe "initialization" do
    it "should initialize a new crawler" do
      c = ClearedJobsNetCrawler.new("all")
      expect(c.instance_variable_get(:@crawl_type)).to eq("all")
    end

    it "should handle search term crawler types" do
      c = ClearedJobsNetCrawler.new("xkeyscore")
      expect(c.instance_variable_get(:@crawl_type)).to eq("search")
      expect(c.instance_variable_get(:@search_term)).to eq("xkeyscore")
    end
  end

  describe "crawler" do
    it "gets initial results page" do
      c = ClearedJobsNetCrawler.new("all")
      results_html = c.run_initial_query
      expect(results_html).to include("Job Openings Worldwide")
    end

    it "gets number of results pages" do
      c = ClearedJobsNetCrawler.new("all")
      query_num_pages = c.get_num_pages_per_query
      expect(query_num_pages).to eq("40")
    end

    it "can get page two" do
      base_query_url = "https://clearedjobs.net/search/action/advanced_search/zip_radius/20/keywords/+/city_state_zip/+/security_clearance/+/submit/SEARCH+JOBS/sort/time"
      c = ClearedJobsNetCrawler.new("all")
      page_html = c.goto_next_page(base_query_url, 2)
      expect(page_html).to include("<strong>2</strong>")
    end

    it "can save listing links for a page" do
      c = ClearedJobsNetCrawler.new("all")
      base_query_url = "https://clearedjobs.net/search/action/advanced_search/zip_radius/20/keywords/+/city_state_zip/+/security_clearance/+/submit/SEARCH+JOBS/sort/time"
      page_html = c.goto_next_page(base_query_url, 2)
      expect(c.collect_page_links(page_html).length).to eq(25)
    end

    it "can save parsed listings for a results page" do
      c = ClearedJobsNetCrawler.new("all")
      base_query_url = "https://clearedjobs.net/search/action/advanced_search/zip_radius/20/keywords/+/city_state_zip/+/security_clearance/+/submit/SEARCH+JOBS/sort/time"
      page_html = c.goto_next_page(base_query_url, 2)
      c.collect_page_links(page_html)
      expect(c.instance_variable_get(:@output).length).to eq(25)
    end

    it "can collect all the listing links for an all query" do
      c = ClearedJobsNetCrawler.new("all")
      c.crawl_listings
      expect(c.instance_variable_get(:@output).length).to eq(1000)
    end

    it "can search for a specific term" do
      c = ClearedJobsNetCrawler.new("SIGINT")
      base_url = c.get_base_query_url
      expect(c.goto_next_page(base_url, 1)).to include ("SIGINT Jobs")
    end

    it "can filter by security clearance" do
      c = ClearedJobsNetCrawler.new("Top Secret / SCI", "security_clearance")
      base_url = c.get_base_query_url
      expect(c.goto_next_page(base_url, 1)).to include("Top Secret / SCI</a>")
      expect(c.goto_next_page(base_url, 1)).to_not include("Top Secret / SCI + Poly</a>")
    end

    it "can filter by country" do
      c = ClearedJobsNetCrawler.new("Germany", "country")
      base_url = c.get_base_query_url
      expect(c.goto_next_page(base_url, 1)).to include("Jobs In Germany")
    end

    it "can load a company page" do
      c = ClearedJobsNetCrawler.new("leidos-0062", "company_page")
      base_url = c.get_base_query_url
      expect(c.goto_next_page(base_url, 1)).to include("11951 Freedom Drive")
    end

    it "can crawl an company page" do
      c = ClearedJobsNetCrawler.new("leidos-0062", "company_page")
      base_url = c.get_base_query_url
      next_page = c.goto_next_page(base_url, 2)
      expect(next_page).to include("<strong>2</strong>")
      expect(c.collect_page_links(next_page).length).to eq(25)
    end
  end

  describe "parser" do
    let(:url) { "https://clearedjobs.net/job/logistics-management-specialist-aberdeen-proving-grounds-maryland-399440" }
    let(:posting_date) { Date.parse( "March 3rd, 2017") }
    let(:html) { File.read(open(url))}
    let(:parser) { ClearedJobsNetParser.new(html, {url: url, posting_date: posting_date}) }
    let(:company) { "Engility" }
    it "should initialize the parser with html" do
      expect(parser.instance_variable_get(:@html).text).to include(company)
    end

    it "should parse company name" do
      expect(parser.company_name).to eq(company)
    end

    it "should parse clearance level" do
      expect(parser.required_clearance).to be_a(String)
    end

    it "should parse location and country" do
      expect(parser.location).to be_a(String)
      expect(parser.country).to be_a(String)
    end

    it "should parse salary and job number" do
      expect(parser.salary).to be_a(String)
      expect(parser.job_number).to be_a(String)
    end

    it "should get the job title" do
      expect(parser.job_title).to be_a(String)
    end

    it "should get the job description" do
      expect(parser.job_description).to be_a(String)
      expect(parser.job_description_plaintext).to be_a(String)
    end

    it "should return a hash of the parsed profile" do
      expect(parser.parse_job).to be_a(Hash)
    end
  end
end
