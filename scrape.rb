require "rubygems"
require "bundler/setup"
Bundler.require(:default)

class Scraper
  BUS_TYPES = ["Contractor/Installer","Distributor","Financial Company or Financial Consultant","Law Firm","Research Laboratory","Manufacturer/Supplier","Utility","Project Developer (Architects, planners, consultants, and builders of solar projects)","Other (non-financial)","Commercial System User","Solar Winery/Brewery/Distillery"]
  STATES = ["AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"]
  
  SEIA_URL = "http://www.seia.org/cs/membership/member_directory"
  
  def self.scrape_page
    # setup user agent
    agent = Mechanize.new
    agent.user_agent_alias = 'Mac Safari'
    
    # get the page
    page = agent.get(SEIA_URL)
    
    # set form values
    form = page.form("search")
    form["filter_equal.member_type.name"] = 'Contractor/Installer'
    form["filter_equal.dm_seia_organization.address.state"] = 'PA'
    form["filter_like.dm_seia_organization.description"] = ''
    
    # submit form, get results page
    result_page = agent.submit(form, form.buttons.first)
    
    # scrape entries from results page
    entries = []
    e = {}
    result_page.search('.results p').each do |p|
      className = p.attr('class')
      
      # 1st/last in sequence for this entry?
      is_first = className == 'company'
      is_last  = className == 'description'
      
      # puts "#{p.attr('class')} => #{p.text}"
      
      e = {} if is_first        #new entry if we just started
      e[className] = p.text.chomp #get next tag in sequence
      entries << e if is_last   #push the entry if we're done
    end
    
    # output each entry
    entries.each_with_index do |e, i|
      e.each_pair do |k, v|
        puts "#{k} => #{v}"
      end
    end
  end
  
  # phone number regex (src: http://blog.stevenlevithan.com/archives/validate-phone-number#r4-2-v-inline)
  def self.phone_number?(txt)
    txt =~ /^(?:\(?([0-9]{3})\)?[-. ]?)?([0-9]{3})[-. ]?([0-9]{4})$/
  end
end

if __FILE__ == $PROGRAM_NAME
  Scraper.scrape_page
  
  # Bundler.require(:test)
  #   
  # describe Scraper, '#scrape_page' do
  #   before(:each) do
  #     file = File.open("sample_data/entry")
  #     @entry = Scraper.parse_entry(file)
  #   end
  #   
  #   it "reads in a sample entry's company name" do
  #     @entry[:name].should == "Advanced Solar Industries, LLC"
  #   end
  # end
end