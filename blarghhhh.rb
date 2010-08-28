require "rubygems"
require "bundler"
Bundler.setup

require "httparty"
require "sinatra"
require "erb"

base_uri = 'http://github.com/api/v2/json/'
userid = 'zacharyscott'
repoid = 'my_blarghhhh'

get '/' do
	@info = HTTParty.get("#{base_uri}repos/show/#{userid}/#{repoid}")
	@blobs = HTTParty.get("#{base_uri}blob/all/#{userid}/#{repoid}/master")
  erb :index
end


