require "rubygems"
require "bundler/setup"
Bundler.require(:default)

File.open("sample_data") do |f|
  # parse the data
end

if __FILE__ == $PROGRAM_NAME
  Bundler.require(:test)
end