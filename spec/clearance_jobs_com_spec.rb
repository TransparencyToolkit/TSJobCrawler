require 'pry'
require 'open-uri'
load 'lib/clearancejobscom/clearance_jobs_com_crawler.rb'
load 'lib/clearancejobscom/clearance_jobs_com_parser.rb'

RSpec.describe ClearanceJobsComCrawler do
  describe "initialization" do
    it "should initialize a new crawler" do
      c = ClearanceJobsComCrawler.new(nil)
      expect(c.instance_variable_get(:@search_term)).to eq(nil)
    end
  end

  describe "crawling some" do
    let(:crawler) { ClearanceJobsComCrawler.new("osint") }

    it "should get the correct base URL" do
      expect(crawler.instance_variable_get(:@base_url)).to eq("https://www.clearancejobs.com/jobs?keywords=osint&zip_text=")
    end

    it "should save the correct # in output" do
      crawler.crawl
      expect(crawler.instance_variable_get(:@output).length).to eq(100)
    end
  end

  describe "crawling all" do
    let(:crawler) { ClearanceJobsComCrawler.new(nil) }

    it "should get the correct base URL" do
      expect(crawler.set_base_url).to eq("https://www.clearancejobs.com/jobs?")
    end
    
    it "should get the correct page count" do
      expect(crawler.get_page_count).to eq(833)
    end
    
    it "should get the correct next page URL" do
      expect(crawler.get_next_page_url(1)).to eq("https://www.clearancejobs.com/jobs?PAGE=1&limit=25")
    end

    it "should download page two" do
      expect(crawler.get_next_page(2)).to include("26 - 50")
    end

    it "should return links on page" do
      page = crawler.get_next_page(1)
      expect(crawler.collect_links_on_page(page).length).to eq(25)
    end

    it "should parse the listings on the page" do
      page = crawler.get_next_page(1)
      links = crawler.collect_links_on_page(page)
      expect(crawler.parse_listings(links)).to be_a(Array)
      expect(crawler.instance_variable_get(:@output).length).to eq(25)
    end
  end

  describe "parsing" do
    let(:page_url) {"https://www.clearancejobs.com/jobs/2398146/nlp-developer"}
    let(:page) { File.read(open(page_url)) }
    let(:parser) { ClearanceJobsComParser.new(page_url, page) }

    let(:page2_url) {"https://www.clearancejobs.com/jobs/2200754/lead-senior-software-engineer"}
    let(:page2) { File.read(open(page2_url))}
    let(:parser2) { ClearanceJobsComParser.new(page2_url, page2) }

    let(:page3_url) {"https://www.clearancejobs.com/jobs/2292914/geospatial-intelligence-manager"}
    let(:page3) { File.read(open(page3_url))}
    let(:parser3) { ClearanceJobsComParser.new(page3_url, page3) }

    it "should initialize a parser for the page" do
      expect(parser.instance_variable_get(:@url)).to eq(page_url)
    end

    it "should get the posting date" do
      expect(parser.posting_date).to eq(DateTime.parse("2017-03-03T13:46:24-0600"))
    end

    it "should get the clearance level" do
      expect(parser.required_clearance).to eq("Secret")
    end

    it "should get the workplace details" do
      expect(parser.work_environment).to eq("On-Site/Office")
    end

    it "should get the required experience" do
      expect(parser.required_experience).to eq("2+ yrs experience")
    end

    it "should get the job status" do
      expect(parser.employment_status).to eq("Employee")
    end

    it "should get the job category" do
      expect(parser.job_category).to eq("IT Software-Java/J2EE")
    end

    it "should get the group ID" do
      expect(parser.group_id).to eq("10445151")
    end

    it "should get the salary" do
      expect(parser2.salary).to eq("$150,000 and above annual salary$50 - $75 hourly wage")
    end

    it "should get compensation notes" do
      expect(parser2.salary_notes).to eq("Compensation is $72.11 - $76.92/hour depending on experience")
    end

    it "should get required travel" do
      expect(parser3.required_travel).to eq("No Traveling")
    end

    it "should get the job title" do
      expect(parser.job_title).to eq("NLP Developer")
    end

    it "should get the company name" do
      expect(parser.company_name).to eq("Orbis Technologies, Inc")
    end

    it "should get the job location" do
      expect(parser.location).to eq("Saint Petersburg, FL")
    end

    it "should get the job description" do
      expect(parser.job_description).to be_a(String)
      expect(parser.job_description_plaintext).to be_a(String)
    end

    it "should return the full parsed profile" do
      expect(parser.parse).to be_a(Hash)
      expect(parser2.parse).to be_a(Hash)
      expect(parser3.parse).to be_a(Hash)
    end
  end
end
