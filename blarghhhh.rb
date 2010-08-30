require "rubygems"
require "bundler"
Bundler.setup

require "haml"
require "httparty"
require "sinatra"
require "erb"
require "rdiscount"
require "builder"
require "dalli"

base_uri = 'http://github.com/api/v2/json'
userid = 'zacharyscott'
repoid = 'my_blarghhhh'


get '/' do
  @dc = Dalli::Client.new('localhost:11211')
  @dc.set('info', HTTParty.get("#{base_uri}/repos/show/#{userid}/#{repoid}"))
  @info = @dc.get('info')	
  @dc.set('collaborators', HTTParty.get("#{base_uri}/repos/show/#{userid}/#{repoid}/collaborators"))
  @collaborators = @dc.get('collaborators')	
  @dc.set('blobs', HTTParty.get("#{base_uri}/blob/all/#{userid}/#{repoid}/master"))
  @blobs = @dc.get('blobs')	
  erb :index
end

get '/show/:post/:sha' do
  @dc = Dalli::Client.new('localhost:11211')
  @dc.set('info', HTTParty.get("#{base_uri}/repos/show/#{userid}/#{repoid}"))
  @info = @dc.get('info')	
  @dc.set('collaborators', HTTParty.get("#{base_uri}/repos/show/#{userid}/#{repoid}/collaborators"))
  @collaborators = @dc.get('collaborators')	
  @dc.set(params[:sha], HTTParty.get("#{base_uri}/blob/show/#{userid}/#{repoid}/#{params[:sha]}").to_s)
  @post = RDiscount.new(@dc.get(params[:sha])).to_html
  @dc.set('history', HTTParty.get("#{base_uri}/commits/list/#{userid}/#{repoid}/master/#{params[:post]}").to_hash)
  @history = @dc.get('history') 
  erb :show
end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

get '/rss.xml' do
  @dc = Dalli::Client.new('localhost:11211')
  @dc.set('info', HTTParty.get("#{base_uri}/repos/show/#{userid}/#{repoid}"))
  @info = @dc.get('info')
  @dc.set('blobs', HTTParty.get("#{base_uri}/blob/all/#{userid}/#{repoid}/master"))
  @blobs = @dc.get('blobs')
  builder do |xml|
    xml.instruct! :xml, :version => '1.0'
    xml.rss :version => "2.0" do
      xml.channel do
        xml.title @info["repository"]["name"]
        xml.description @info["repository"]["description"]
        xml.link @info["repository"]["homepage"]
        
        @blobs["blobs"].each_pair do |key, value|
          @dc.set("hist-#{value}", HTTParty.get("#{base_uri}/commits/list/#{userid}/#{repoid}/master/#{key}").to_hash)
          hist = @dc.get("hist-#{value}") 
          xml.item do
            xml.title key
            xml.link "#{@info["repository"]["homepage"]}/show/#{key}/#{value}"            
            xml.guid "#{@info["repository"]["homepage"]}/show/#{key}/#{value}"
            xml.pubDate Time.parse("#{hist["commits"][0]["authored_date"]}".to_s).rfc822()	
          end
        end
      end
    end
  end
end


