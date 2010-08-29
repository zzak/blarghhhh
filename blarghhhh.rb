require "rubygems"
require "bundler"
Bundler.setup

require "haml"
require "httparty"
require "sinatra"
require "erb"
require "rdiscount"
require "builder"

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
  
  @history = HTTParty.get("#{base_uri}commits/list/#{userid}/#{repoid}/master/#{params[:post]}").to_hash
  erb :show
end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

get '/rss.xml' do
  @info = HTTParty.get("#{base_uri}repos/show/#{userid}/#{repoid}")
  @blobs = HTTParty.get("#{base_uri}blob/all/#{userid}/#{repoid}/master")
  
  builder do |xml|
    xml.instruct! :xml, :version => '1.0'
    xml.rss :version => "2.0" do
      xml.channel do
        xml.title @info["repository"]["name"]
        xml.description @info["repository"]["description"]
        xml.link @info["repository"]["homepage"]
        
        @blobs["blobs"].each_pair do |key, value|
          
          xml.item do
            xml.title key
            xml.link "#{@info["repository"]["homepage"]}/show/#{key}/#{value}"            
            xml.guid "#{@info["repository"]["homepage"]}/show/#{key}/#{value}"
          end
        end
      end
    end
  end
end


