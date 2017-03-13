#require 'pry'
require 'open-uri'
#require 'nokogiri'

load 'util/failure_handler.rb'

class ClearanceJobsComParser
  include FailureHandler
  def initialize(url, page, requests=nil)
    @url = url
    @requests = requests
    @i = 0
    @html = page
    @page = Nokogiri::HTML.parse(page)
  end

  # Parse the profile
  def parse
    begin
      return {
        url: @url,
        company_name: company_name,
        location: location,
        job_title: job_title,
        job_description: job_description,
        job_description_plaintext: job_description_plaintext,
        required_travel: required_travel,
        salary: salary,
        salary_notes: salary_notes,
        job_category: job_category,
        group_id: group_id,
        required_experience: required_experience,
        employment_status: employment_status,
        required_clearance: required_clearance,
        required_experience: required_experience,
        work_environment: work_environment,
        posting_date: posting_date,
        html: @html
      }
    rescue
      @i += 1
      if @i < 10
        @html = Nokogiri::HTML.parse(get_retry(@url, @requests, @i))
        parse
      end
    end
  end
  
  # Get the company name
  def company_name
    @page.css("h2").text
  end

  # Get the job location
  def location
    raw_location = @page.css("div").select{|e| e['itemprop'] == "hiringOrganization"}[0].css("h3").text
    raw_location.gsub(/(\d)/, "").strip if raw_location
  end

  # Get the job title
  def job_title
    @page.css("h1").text
  end

  # Get the job description
  def job_description
    @page.css("div.margin-bottom-20").select{|e| e['itemprop'] == "description"}[0].to_html
  end

  # Get the job description without text
  def job_description_plaintext
    Nokogiri::HTML.parse(job_description.gsub('<br />',"\n").gsub('<br>', "\n").gsub('<br/>', "\n")).text
  end
  
  # Get if there is travel required
  def required_travel
    get_element_value("Travel:")
  end
  
  # Get the salary
  def salary
    get_element_value("Compensation:")
  end

  # Get notes about the salary
  def salary_notes
    salary_info = get_element_value("Compensation Comments:")
    salary_info.lstrip.strip if salary_info
  end

  # Get the job category
  def job_category
    get_element_value("Job Category:")
  end

  # Get the group ID
  def group_id
    get_element_value("Group ID")
  end

  # Get the # of years of experience required
  def required_experience
    get_element_value("Minimum Experience Required")  
  end

  # Get the employment status for the position
  def employment_status
    get_element_value("Status:")
  end

  # Get the clearance level
  def required_clearance
    get_element_value("Minimum Clearance")
  end

  # Get the work environment
  def work_environment
    get_element_value("Workplace:")
  end

  # Get the date of the posting
  def posting_date
    element = get_element("Post Date:")
    DateTime.parse(element[0].css("meta")[0]['content'])
  end

  # Get the value for the element
  def get_element_value(phrase)
    element = get_element(phrase)[0]
    element.css("strong").text if element
  end

  # Get the element including the phrase specified
  def get_element(phrase)
    @page.css(".cj-job-data").select{|d| d.text.include?(phrase) }
  end
end
