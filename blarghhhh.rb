require "rubygems"
require "bundler"
Bundler.setup

require "sass"
require "httparty"
require "sinatra/base"
require "erb"
require "rdiscount"
require "builder"
require "sinatra-sindalli"

class Blarghhhh < Sinatra::Base
  register Sinatra::SinDalli
  
  set :base_uri, 'http://github.com/api/v2/json'
  set :userid, 'zacharyscott'
  set :repoid, 'my_blarghhhh'
  
  #set :cache, Sinatra::SinDalli.new('override')

  get '/' do
    @info = settings.cache.fetch("info-#{settings.repoid}") do
      HTTParty.get("#{settings.base_uri}/repos/show/#{settings.userid}/#{settings.repoid}")
    end
    
    @collaborators = settings.cache.fetch("collaborators-#{settings.repoid}") do
      HTTParty.get("#{settings.base_uri}/repos/show/#{settings.userid}/#{settings.repoid}/collaborators")
    end
    
    @blobs = settings.cache.fetch("blobs-#{settings.repoid}") do
      HTTParty.get("#{settings.base_uri}/blob/all/#{settings.userid}/#{settings.repoid}/master")
    end	
    
    erb :index
  end

  get '/show/:post/:sha' do
    @info = settings.cache.fetch("info-#{settings.repoid}") do
      HTTParty.get("#{settings.base_uri}/repos/show/#{settings.userid}/#{settings.repoid}")
    end
    
    @collaborators = settings.cache.fetch("collaborators-#{settings.repoid}") do
      HTTParty.get("#{settings.base_uri}/repos/show/#{settings.userid}/#{settings.repoid}/collaborators")
    end
    
    settings.cache.fetch("#{params[:sha]}-#{settings.repoid}") do
      HTTParty.get("#{settings.base_uri}/blob/show/#{settings.userid}/#{settings.repoid}/#{params[:sha]}").to_s
    end
    @post = RDiscount.new(settings.cache.get("#{params[:sha]}-#{settings.repoid}")).to_html
    
    @history = settings.cache.fetch("history-#{settings.repoid}") do
      HTTParty.get("#{settings.base_uri}/commits/list/#{settings.userid}/#{settings.repoid}/master/#{params[:post]}").to_hash
    end
    
    erb :show
  end

  get '/stylesheet.css' do
    content_type 'text/css', :charset => 'utf-8'
    sass :stylesheet
  end

  get '/rss' do
    @info = settings.cache.fetch("info-#{settings.repoid}") do
      HTTParty.get("#{settings.base_uri}/repos/show/#{settings.userid}/#{settings.repoid}")
    end
    
    @blobs = settings.cache.fetch("blobs-#{settings.repoid}") do
      HTTParty.get("#{settings.base_uri}/blob/all/#{settings.userid}/#{settings.repoid}/master")
    end
    
    builder do |xml|
      xml.instruct! :xml, :version => '1.0'
      xml.rss :version => "2.0" do
        xml.channel do
          xml.title @info["repository"]["name"]
          xml.description @info["repository"]["description"]
          xml.link @info["repository"]["homepage"]
          
          @blobs["blobs"].each_pair do |key, value|
            settings.cache.set("hist-#{value}", HTTParty.get(
              "#{settings.base_uri}/commits/list/#{settings.userid}/#{settings.repoid}/master/#{key}").to_hash)
            hist = settings.cache.get("hist-#{value}") 
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

end

