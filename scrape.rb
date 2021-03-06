require "rubygems"
require "bundler/setup"
Bundler.require(:default)
require 'csv'

class Scraper
  # form field names
  FIELDNAME_BUS_TYPE = "filter_equal.member_type.name"
  FIELDNAME_STATE    = "filter_equal.dm_seia_organization.address.state"
  FIELDNAME_KEYWORDS = "filter_like.dm_seia_organization.description"
  
  # form field vals
  FIELDVALS_BUS_TYPES = ["Contractor/Installer","Distributor","Financial Company or Financial Consultant","Law Firm","Research Laboratory","Manufacturer/Supplier","Utility","Project Developer (Architects, planners, consultants, and builders of solar projects)","Other (non-financial)","Commercial System User","Solar Winery/Brewery/Distillery"]
  FIELDVALS_STATES    = ["AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"]
  
  CLASS_NAMES = ['company', 'website', 'name', 'addr1', 'addr2', 'addr_rest', 'phone', 'description', 'state', 'bus_type']
  
  SEIA_URL = "http://www.seia.org/cs/membership/member_directory"
  
  OUTPUT_FILENAME = "OUTPUT.csv"
  
  def self.scrape_page
    # setup user agent
    agent = Mechanize.new
    agent.user_agent_alias = 'Mac Safari'
        
    entries = []
    
    # every state and business type
    FIELDVALS_STATES.each do |state|
      FIELDVALS_BUS_TYPES.each do |bus_type|
        
        # get the results page
        puts "+++++++++++++++++++++++++++++++++++++++++"
        puts "GETTING RESULTS FOR #{state}, #{bus_type}"
        results_page = form_page_results(agent, state, bus_type)
        
        # parse entries from page
        puts "PARSING RESULTS..."
        page_entries = Scraper.parse_results_page(results_page, state, bus_type)
      
        # concat result entries
        entries.concat(page_entries)
      end
    end
    
    Scraper.write_entries_to_csv(entries)
  end
  
  def self.form_page_results(agent, state, bus_type)
    # get the page
    page = agent.get(SEIA_URL)

    # set form values
    form = page.form("search")
    form[FIELDNAME_BUS_TYPE] = bus_type
    form[FIELDNAME_STATE]    = state
    form[FIELDNAME_KEYWORDS] = ''
    
    # submit form, get results page
    results_page = agent.submit(form, form.buttons.first)
  end
  
  def self.write_entries_to_csv(entries)
    # output to CSV file
    CSV.open(OUTPUT_FILENAME, "wb") do |csv|
      csv << CLASS_NAMES
      entries.each do |e|
        csv << CLASS_NAMES.map {|c| e[c]}
      end
    end
  end
  
  def self.parse_results_page(page, state, bus_type)
    # scrape entries from results page
    entries = []
    e = {}
    page.search('.results p').each do |p|
      className = p.attr('class')

      next if className.nil?
      
      #make friendly for Ruby method names
      className.gsub!('-', '_')
      
      # 1st/last in sequence for this entry?
      is_first = className == 'company'
      is_last  = className == 'description'
      
      #new entry if we just started
      e = {} if is_first          
      
      #get next tag in sequence
      e[className] = Scraper.sanitize_str(p.text)
      
      #push the entry if we're done
      if is_last
        e['state']    = state
        e['bus_type'] = bus_type
        entries << e 
      end
    end
    
    entries
  end
  
  def self.sanitize_str(str)
    str.gsub("\r", '').gsub("\n", '').squeeze(' ').strip
  end
  
  # phone number regex (src: http://blog.stevenlevithan.com/archives/validate-phone-number#r4-2-v-inline)
  def self.phone_number?(txt)
    txt =~ /^(?:\(?([0-9]{3})\)?[-. ]?)?([0-9]{3})[-. ]?([0-9]{4})$/
  end
end

# RSpec tests
if __FILE__ == $PROGRAM_NAME
  Scraper.scrape_page
end