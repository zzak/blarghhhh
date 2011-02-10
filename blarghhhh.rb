require "rubygems"
require "bundler"
Bundler.setup

require "sass"
require "httparty"
require "sinatra/base"
require "erb"
require "rdiscount"
require "dalli"
require "yaml"

class Blarghhhh < Sinatra::Base

  set :base_uri, 'http://github.com/api/v2/json'
  set :userid, ENV['GITHUB_USER']
  set :repoid, ENV['GITHUB_REPO']
  
  set :public, File.dirname(__FILE__) + '/public'

  set :cache, Dalli::Client.new(ENV['MEMCACHE_SERVERS'], :username => ENV['MEMCACHE_USERNAME'], :password => ENV['MEMCACHE_PASSWORD'], :expires_in => 300)

  get '/' do
    @info = settings.cache.fetch("info") do
      HTTParty.get("#{settings.base_uri}/repos/show/#{settings.userid}/#{settings.repoid}")
    end
    
    @collaborators = settings.cache.fetch("collaborators") do
      HTTParty.get("#{settings.base_uri}/repos/show/#{settings.userid}/#{settings.repoid}/collaborators")
    end
    
    @blobs = settings.cache.fetch("blobs") do
      HTTParty.get("#{settings.base_uri}/blob/all/#{settings.userid}/#{settings.repoid}/master")
    end	
    
    erb :index
  end

  get '/show/:post/:sha' do
    @info = settings.cache.fetch("info") do
      HTTParty.get("#{settings.base_uri}/repos/show/#{settings.userid}/#{settings.repoid}")
    end
    
    @collaborators = settings.cache.fetch("collaborators") do
      HTTParty.get("#{settings.base_uri}/repos/show/#{settings.userid}/#{settings.repoid}/collaborators")
    end
    
    markdown = settings.cache.fetch("#{params[:sha]}") do
      HTTParty.get("#{settings.base_uri}/blob/show/#{settings.userid}/#{settings.repoid}/#{params[:sha]}").to_s
    end
    @post = RDiscount.new(markdown).to_html
    
    @history = settings.cache.fetch("#{params[:sha]}-history") do
      HTTParty.get("#{settings.base_uri}/commits/list/#{settings.userid}/#{settings.repoid}/master/#{params[:post]}").to_hash
    end
    
    erb :show
  end

  get '/stylesheet.css' do
    content_type 'text/css', :charset => 'utf-8'
    sass :stylesheet
  end

end
