require "rubygems"
require "bundler/setup"
Bundler.require(:default)

class Scraper
  LINE_IDX_NAME    = 0
  LINE_IDX_URL     = 1
  LINE_IDX_CONTACT = 2
  LINE_IDX_ADR_1   = 3
  LINE_IDX_ADR_2   = 4
  LINE_IDX_PHONE   = 5
  LINE_IDX_DESC    = 6
  
  def self.parse_file(filename)    
    entries = []
    
    File.open(filename) do |f|
      entry = Scraper.parse_entry(file)
      break if entry.empty?
      
      entries << entry
    end
  end
  
  def self.parse_entry(file)
    line_idx = 0
    done = false
    entry = {}
    
    begin
      if line = file.gets.chomp
        
        #classify line and add to the hash based on line index
        case line_idx
        when LINE_IDX_NAME
          entry[:name] = line
        when LINE_IDX_URL
          entry[:url] = line
        when LINE_IDX_CONTACT
          entry[:contact] = line
        when LINE_IDX_ADR_1
          entry[:adr_1] = line
        when LINE_IDX_ADR_2
          entry[:adr_2] = line
        when LINE_IDX_PHONE
          entry[:phone] = line
        when LINE_IDX_DESC
          entry[:desc] = line
          done = true
        end

        #update line index
        line_idx += 1
      end
      
    end while !done
    
    entry
  end
end

if __FILE__ == $PROGRAM_NAME
  Bundler.require(:test)
    
  describe Scraper, '#parse_entry' do
    before(:each) do
      file = File.open("sample_data/entry")
      @entry = Scraper.parse_entry(file)
    end
    
    it "reads in the first entry's company name" do
      @entry[:name].should == "Advanced Solar Industries, LLC"
    end
    it "reads in the first entry's website" do
      @entry[:url].should == "www.advancedsolarindustries.com"
    end
    it "reads in the first entry's contact" do
      @entry[:contact].should == "Elam Beiler"
    end
    it "reads in the first entry's address line 1" do
      @entry[:adr_1].should == "3530 W. Newport Road"
    end
    it "reads in the first entry's address line 2" do
      @entry[:adr_2].should == "Ronks, PA 17542"
    end
    it "reads in the first entry's phone number" do
      @entry[:phone].should == "717-768-8500"
    end
    it "reads in the first entry's description" do
      @entry[:desc].should == "Advanced Solar Industries is an installer of grid-tie systems primarily utilizing SunPower brand solar panels. We also have over 15 years of experience installing off-grid solar systems."
    end
  end
end