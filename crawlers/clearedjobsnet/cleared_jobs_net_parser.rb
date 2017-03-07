require 'nokogiri'
require 'pry'
require 'open-uri'

load 'util/failure_handler.rb'

class ClearedJobsNetParser
  include FailureHandler
  def initialize(html, details_hash, requests=nil)
    @html = Nokogiri::HTML.parse(html)
    @requests = requests
    @url = details_hash[:url]
    @i = 0
    @posting_date = details_hash[:posting_date]
  end

  # Parses the job
  def parse_job
    begin
      return {
        url: @url,
        html: @html.to_html,
        posting_date: @posting_date,
        company_name: company_name,
        company_listing_link: company_listing_link,
        required_clearance: required_clearance,
        location: location,
        country: country,
        salary: salary,
        job_number: job_number,
        job_title: job_title,
        job_description: job_description,
        job_description_plaintext: job_description_plaintext
      }
    rescue
      @i += 1
      if @i < 10
        @html = Nokogiri::HTML.parse(get_retry(@url, @requests, @i))
        parse_job
      end
    end
  end

  # Gets the company name
  def company_name
    @html.css("div.view_job_table").css("div.row")[0].css(".left2").text
  end

  # Get the link to the company page
  def company_listing_link
    @html.css("div.view_job_table").css("div.row")[0].css(".left2").css("a")[0]['href']
  end

  # Gets the clearance level required
  def required_clearance
    @html.css("div.view_job_table").css("div.row")[0].css(".clearAll")[1].text
  end

  # Get the location of work
  def location
    @html.css("div.view_job_table").css("div.row")[1].css(".left2").text
  end

  # Get the country of work
  def country
    @html.css("div.view_job_table").css("div.row")[1].css(".right2").text
  end

  # Get the salary
  def salary
    @html.css("div.view_job_table").css("div.row")[2].css(".left2").text.strip.lstrip
  end

  # Get the job number
  def job_number
    @html.css("div.view_job_table").css("div.row")[2].css(".right2").text.strip.lstrip
  end

  # Get the job title
  def job_title
    @html.css("#view_employer").text
  end

  # Get the job description
  def job_description
    @html.css(".view-job-right").to_html
  end

  # Get the job description without HTML
  def job_description_plaintext
    Nokogiri::HTML.parse(job_description.gsub('<br />',"\n").gsub('<br>', "\n").gsub('<br/>', "\n")).text
  end
end
