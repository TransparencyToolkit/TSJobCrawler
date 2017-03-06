require 'nokogiri'
require 'open-uri'
require 'pry'

load 'crawlers/util/failure_handler.rb'

class SecurityClearedJobsComParser
  include FailureHandler
  def initialize(url, html, requests=nil)
    @url = url
    @requests = requests
    @html = html
    @page = Nokogiri::HTML.parse(@html)
  end

  # Parse the job listing
  def parse
    begin
      return {
        url: @url,
        company_name: company_name,
        location: location,
        salary: salary,
        posting_date: posting_date,
        closing_date: closing_date,
        job_number: job_number,
        contact_person: contact_person,
        employment_status: employment_status,
        required_clearance: required_clearance,
        job_category: job_category,
        job_title: job_title,
        job_description: job_description,
        job_description_plaintext: job_description_plaintext,
        html: @html
      }
    rescue
      @i += 1
      if i < 10
        @html = Nokogiri::HTML.parse(get_retry(@url, @requests, @i))
        parse
      end
    end
  end

  # Get the name of the company
  def company_name
    @page.css("div.cf[itemprop='hiringOrganization']")[0].css("span[itemprop='name']").text
  end

  # Get the location
  def location
    get_element("Location")
  end

  # Get the salary
  def salary
    get_element("Salary")
  end

  # Get the posting date
  def posting_date
    Date.parse(get_element("Posted"))
  end

  # Get the date it closes
  def closing_date
    Date.parse(get_element("Closes"))
  end

  # Get the job number
  def job_number
    get_element("Ref")
  end

  # Get the contact person
  def contact_person
    get_element("Contact")
  end

  # Get the employment status
  def employment_status
    get_element("Job Type")
  end

  # Gets the clearance level required
  def required_clearance
    get_element("Clearance Level").split(", ")
  end

  # Gets the sector of the job
  def job_category
    get_element("Sector").split(", ")
  end

  # Get the job title
  def job_title
    @page.css("h1[itemprop='title']").text
  end

  # Get the job description
  def job_description
    @page.css("div[itemprop='description']").to_html
  end

  # Get the job description without html
  def job_description_plaintext
    Nokogiri::HTML.parse(job_description.gsub('<br />',"\n").gsub('<br>', "\n").gsub('<br/>', "\n")).text
  end

  # Get the element for the field
  def get_element(field_name)
    element = @page.css("div.cf").select{|d| d.text.include?(field_name)}
    element[0].css("dd").text.strip.lstrip.gsub(/\s+/, " ") if !element.empty?
  end
end
