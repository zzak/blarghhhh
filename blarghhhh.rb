require "rubygems"
require "bundler"
Bundler.setup

require "haml"
require "sass"
require "httparty"
require "sinatra/base"
require "rdiscount"
require "dalli"

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
    @branches = settings.cache.fetch("branches") do
      HTTParty.get("#{settings.base_uri}/repos/show/#{settings.userid}/#{settings.repoid}/branches")
    end
    haml :index
  end

  get '/b/:branch' do
    @info = settings.cache.fetch("info") do
      HTTParty.get("#{settings.base_uri}/repos/show/#{settings.userid}/#{settings.repoid}")
    end
    @collaborators = settings.cache.fetch("collaborators") do
      HTTParty.get("#{settings.base_uri}/repos/show/#{settings.userid}/#{settings.repoid}/collaborators")
    end
    @blobs = settings.cache.fetch("#{params[:branch]}-blobs") do
      HTTParty.get("#{settings.base_uri}/blob/all/#{settings.userid}/#{settings.repoid}/#{params[:branch]}")
    end	
    haml :branch
  end

  get '/show/:branch/:post/:sha' do
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
      HTTParty.get("#{settings.base_uri}/commits/list/#{settings.userid}/#{settings.repoid}/#{params[:branch]}/#{params[:post]}").to_hash
    end
    haml :show
  end

  get '/stylesheet.css' do
    content_type 'text/css', :charset => 'utf-8'
    sass :stylesheet
  end
end
