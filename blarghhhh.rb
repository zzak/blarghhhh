require "rubygems"
require "bundler"
Bundler.setup

require "haml"
require "httparty"
require "sinatra"
require "erb"
require "rdiscount"

base_uri = 'http://github.com/api/v2/json/'
userid = 'zacharyscott'
repoid = 'my_blarghhhh'


get '/' do
  @info = HTTParty.get("#{base_uri}repos/show/#{userid}/#{repoid}")
  @collaborators = HTTParty.get("#{base_uri}repos/show/#{userid}/#{repoid}/collaborators")
  @blobs = HTTParty.get("#{base_uri}blob/all/#{userid}/#{repoid}/master")
  erb :index
end

get '/show/:post/:sha' do
  @info = HTTParty.get("#{base_uri}repos/show/#{userid}/#{repoid}")
  @collaborators = HTTParty.get("#{base_uri}repos/show/#{userid}/#{repoid}/collaborators")
  doc = HTTParty.get("#{base_uri}blob/show/#{userid}/#{repoid}/#{params[:sha]}").to_s
  @post = RDiscount.new(doc).to_html
  @current = HTTParty.get("#{base_uri}commits/show/#{userid}/#{repoid}/#{params[:sha]}")
  @history = HTTParty.get("#{base_uri}commits/show/#{userid}/#{repoid}/master/#{params[:post]}")
  erb :show
end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

