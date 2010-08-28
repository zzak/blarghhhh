require "rubygems"
require "bundler"
Bundler.setup

require "httparty"
require "sinatra"
require "erb"
require "rdiscount"

base_uri = 'http://github.com/api/v2/json/'
userid = 'zacharyscott'
repoid = 'my_blarghhhh'

get '/' do
	@info = HTTParty.get("#{base_uri}repos/show/#{userid}/#{repoid}")
	@blobs = HTTParty.get("#{base_uri}blob/all/#{userid}/#{repoid}/master")
  erb :index
end

get '/show/:post/:sha' do
	@info = HTTParty.get("#{base_uri}repos/show/#{userid}/#{repoid}")
  doc = HTTParty.get("#{base_uri}blob/show/#{userid}/#{repoid}/#{params[:sha]}").to_s
  @post = RDiscount.new(doc).to_html
  erb :show
end


