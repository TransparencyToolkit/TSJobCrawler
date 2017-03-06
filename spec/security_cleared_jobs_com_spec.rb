# coding: utf-8
require 'pry'
require 'open-uri'
require 'nokogiri'
load 'crawlers/securityclearedjobscom/security_cleared_jobs_com_crawler.rb'
load 'crawlers/securityclearedjobscom/security_cleared_jobs_com_parser.rb'

RSpec.describe SecurityClearedJobsComCrawler do
  describe "initialization" do
    let(:crawler) { SecurityClearedJobsComCrawler.new(nil) }
    
    it "should initialize a new crawler" do
      expect(crawler.instance_variable_get(:@search_term)).to eq(nil)
    end

    it "should get the correct base URL" do
      base_url = "https://www.securityclearedjobs.com/searchjobs/?countrycode=GB"
      expect(crawler.instance_variable_get(:@query_base_url)).to eq(base_url)
    end
  end

  describe "crawling" do
    let(:crawler) { SecurityClearedJobsComCrawler.new(nil) }
    let(:base_url) { crawler.instance_variable_get(:@query_base_url) }
    
    it "should load the search results page" do
      expect(crawler.get_page(base_url)).to include("<h1>Found ")
    end

    it "should get the total number of pages" do
      expect(crawler.get_total_pagecount).to eq(61)
    end

    it "should load the next page" do
      html = Nokogiri::HTML.parse(crawler.load_next_page(2))
      active_link = html.css(".paginator__item--active").text
      expect(active_link).to eq("2")
    end

    it "should save the links on a single search page" do
      page = crawler.load_next_page(1)
      expect(crawler.save_result_links(page).length).to eq(20)
    end
  end

  describe "crawling with a search query" do
    let(:crawler) { SecurityClearedJobsComCrawler.new("ruby") }
    let(:crawler2) { SecurityClearedJobsComCrawler.new("intelligence analyst") }

    it "should get the correct base URL" do
      base_url = "https://www.securityclearedjobs.com/searchjobs/?countrycode=GB&Keywords=ruby"
      expect(crawler.instance_variable_get(:@query_base_url)).to eq(base_url)
    end

    it "should parse all the listings on one page" do
      page = crawler.load_next_page(1)
      expect(crawler.parse_listings(page).length).to eq(4)
      expect(crawler.instance_variable_get(:@output).length).to eq(4)
    end

    it "should crawl all the listings" do
      crawler.crawl
      crawler2.crawl
      expect(crawler.instance_variable_get(:@output).length).to eq(4)
      expect(crawler2.instance_variable_get(:@output).length).to eq(38)
    end
  end

  describe "parsing" do
    let(:listing_url) { "https://www.securityclearedjobs.com/job/801819567/project-manager/" }
    let(:listing_page) { File.read(open(listing_url)) }
    let(:parser) { SecurityClearedJobsComParser.new(listing_url, listing_page) }

    let(:listing_url2) { "https://www.securityclearedjobs.com/job/801819579/logistics-co-ordinator/" }
    let(:listing_page2) { File.read(open(listing_url2)) }
    let(:parser2) { SecurityClearedJobsComParser.new(listing_url2, listing_page2) }

    it "should initialize a parser" do
      expect(parser.instance_variable_get(:@url)).to eq(listing_url)
    end

    it "should get the company name" do
      expect(parser.company_name).to eq("Modis International")
    end

    it "should get the job location" do
      expect(parser.location).to eq("Middlesex")
    end

    it "should get the salary" do
      expect(parser.salary).to eq("£45000 - £55000 per annum + bonuses")
    end

    it "should get the posting and closing dates" do
      expect(parser.posting_date).to eq(Date.parse("03 Mar 2017"))
      expect(parser.closing_date).to eq(Date.parse("31 Mar 2017"))
    end

    it "should get the job number" do
      expect(parser.job_number).to eq("1138920")
    end

    it "should get the contact person" do
      expect(parser.contact_person).to eq("Steven Mitchell")
    end

    it "should get the employment status" do
      expect(parser.employment_status).to eq("Permanent")
    end

    it "should get the classification level" do
      expect(parser2.required_clearance).to eq(["DV", "None / Undisclosed", "SC"])
    end

    it "should get the industry" do
      expect(parser2.job_category).to eq(["Aerospace", "Defence", "Engineering", "Manufacturing"])
    end

    it "should get the job title" do
      expect(parser2.job_title).to eq("Logistics Co-ordinator")
    end

    it "should get the job description" do
      expect(parser2.job_description).to be_a(String)
      expect(parser2.job_description_plaintext).to be_a(String)
    end

    it "should parse the job" do
      expect(parser.parse).to be_a(Hash)
      expect(parser2.parse).to be_a(Hash)
    end
  end
end
