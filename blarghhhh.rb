require "haml"
require "sass"
require "httparty"
require "sinatra"
require "rdiscount"
require "dalli"

set :base_uri, 'http://github.com/api/v2/json'
set :userid, ENV['GITHUB_USER']
set :repoid, ENV['GITHUB_REPO']
set :public, File.dirname(__FILE__) + '/public'
set :cache, Dalli::Client.new(
    ENV['MEMCACHE_SERVERS'], 
    :username => ENV['MEMCACHE_USERNAME'], 
    :password => ENV['MEMCACHE_PASSWORD'], 
    :expires_in => 300)

set :markdown, :layout_engine => :haml
set :views, File.dirname(__FILE__)

get '/' do
  @info = settings.cache.fetch("info") do
    HTTParty.get("#{settings.base_uri}/repos/show/#{settings.userid}/#{settings.repoid}")
  end
  @user = settings.cache.fetch("user") do
    HTTParty.get("#{settings.base_uri}/user/show/#{settings.userid}")
  end
  @blobs = settings.cache.fetch("blobs") do
    HTTParty.get("#{settings.base_uri}/blob/all/#{settings.userid}/#{settings.repoid}/master")
  end
  haml :index
end

get '/show/:post/:sha' do
  @info = settings.cache.fetch("info") do
    HTTParty.get("#{settings.base_uri}/repos/show/#{settings.userid}/#{settings.repoid}")
  end
  @user = settings.cache.fetch("user") do
    HTTParty.get("#{settings.base_uri}/user/show/#{settings.userid}")
  end
  markdown = settings.cache.fetch("#{params[:sha]}") do
    HTTParty.get("#{settings.base_uri}/blob/show/#{settings.userid}/#{settings.repoid}/#{params[:sha]}").to_s
  end
  @post = RDiscount.new(markdown).to_html
  @history = settings.cache.fetch("#{params[:sha]}-history") do
    HTTParty.get("#{settings.base_uri}/commits/list/#{settings.userid}/#{settings.repoid}/master/#{params[:post]}").to_hash
  end
  haml :show
end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

__END__

@@layout
!!!html
%html{:lang=>"en"}
  %head
    %meta{:charset=>"utf-8"} 
    %title
      = "#{@info["repository"]["name"]} | #{@info["repository"]["description"]}"
    %link{:rel=>"stylesheet", :href=>"/stylesheet.css", :type=>"text/css"}
  %body
    #header
      = haml(:header, :layout=>false)
    #content
      #main
        = yield 
      #sidebar
        = haml(:sidebar, :layout=>false)
    = haml(:footer, :layout=>false)
    

@@index
- @blobs["blobs"].each_pair do |key, value|
  %h1{:class=>"post_title"}
    %a{:href=>"/show/#{key}/#{value}"}= key

@@header
%ul#blog_stats
  %li
    %a{:href=>"https://github.com/#{settings.userid}/#{settings.repoid}/commits/master.atom"}
      %img{:src=>"/images/rss.png"}
  %li
    %a{:href=>"https://github.com/#{settings.userid}/#{settings.repoid}/watchers"}
      = @info["repository"]["watchers"]
      %img{:src=>"/images/watchers.png"}
  %li
    %a{:href=>"https://github.com/#{settings.userid}/#{settings.repoid}/network"}
      = @info["repository"]["forks"]
      %img{:src=>"/images/forks.png"}

%h1
  %a{:href=>"#{@info["repository"]["homepage"]}"}
    = @info["repository"]["name"]
%p= @info["repository"]["description"]

@@footer
#footer
  Official blog repo at 
  %a{:href=>"#{@info["repository"]["url"]}"}
    github
  Powered by 
  %a{:href=>"http://github.com/zzak/blarghhhh"}
    blarghhhh

@@sidebar
%img#avatar{:src=>"http://www.gravatar.com/avatar/#{@user["user"]["gravatar_id"]}"}
%h1#username
  = @user["user"]["name"]
  %a{:href=>"http://github.com/#{settings.userid}/followers"}
    %sup= @user["user"]["followers_count"]
%h2#location= @user["user"]["location"]
%ul#user_stats
  %li
    %a{:href=>@user["user"]["blog"]} home
  %li
    %a{:href=>"http://github.com/#{@user["user"]["login"]}"} code
  %li
    %a{:href=>"mailto:#{@user["user"]["email"]}"} email

@@show
#post_info
  %h2 Author
  %p#author_name
    By
    %a{:href=>"http://github.com/#{@history["commits"][0]["author"]["login"]}"}
      = @history["commits"][0]["author"]["name"]
  %h2 Last Update
  %p#authored_date
    = @history["commits"][0]["authored_date"].strftime("%A %B %d %Y at %I:%M%p")
  %h2#history_button History
  #history
    - @history["commits"].each do |commit|
      .commit
        %p.commit_message= commit["message"]
        %p.commit_date= commit["authored_date"].strftime("%A %B %d %Y at %I:%M%p")
#post
  = @post

@@stylesheet
* 
  margin: 0
  padding: 0
  border: 0
  outline: 0 

body
  color: #EEEEEE
  background-color: #2F2F2F 
  font-family: "Lucida Grande", "Lucida Sans Unicode", "Garuda" 

a:link, a:visited 
  color: #5F5F5F

a:hover, a:active 
  color: #8F8F8F

h1 a, h2 a
  text-decoration: none
  
#header
  clear: both
  padding: 20px
  min-height: 40px
  h1
    text-align: right 
  p
    float: right
  ul
    list-style-type: none
  #blog_stats
    float: right
    font-size: .8em
    text-align: right
    margin: 10px 0 0 15px
    a
      text-decoration: none

#content 
  clear: both
  width: 98%
  margin: 10px auto

#main 
  width: 80%
  float: left 
  h1
    line-height: 1.3em

#sidebar 
  margin-top: 100px
  width: 19%
  float: right
  h1 
    font-size: 1.1em
    text-align: right
    sup
      font-size: .8em
  h2 
    font-size: 1em
    color: #4F4F4F
    text-align: right  
  ul 
    list-style-type: none
    margin-left: 20px
  #user_stats
    text-align: right 
    li
      float: left
      margin-left: 10px
  #avatar
    float: left

.page_header
  margin: 20px

.post_title
  line-height: 30px
  margin-bottom: 25px

#post_info
  float: right
  width: 25%
  background: #3F3F3F
  padding: 20px
  color: #EEEEEE
  a:link, a:visited
    color: #EEE
  a:hover, a:active
    color: FFF
  h2
    text-align: right
    color: #2F2F2F
  #authored_date
    font-size: 14px

#post
  float: left
  width: 68%
  ul
    list-style-position: inside
    margin-left: 20px
  p
    line-height: 1.3em
    margin: 10px 0px
  pre
    background: #3F3F3F
    overflow: auto
    overflow-Y: hidden

#history_button
  cursor: pointer

#history
  line-height: 17px
  .commit
    margin-bottom: 10px
  .commit_date
    font-size: 12px
    color: #5F5F5F

#footer 
  clear: both
  text-align: center
  font-size: .8em 
  a:link, a:visited 
    color: #9F9F9F
  a:hover, a:active 
    color: #EEE
 
