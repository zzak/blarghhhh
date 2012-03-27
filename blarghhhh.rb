require "builder"
require "data_mapper"
require "glorify"
require "haml"
require "httparty"
require "json"
require "sass"
require "sinatra"

set :base_uri, 'http://github.com/api/v2/json'
set :ga_id, ENV['GA_ID'] || 'UA-26071793-1'
set :ga_domain, ENV['GA_DOMAIN'] || 'blog.zacharyscott.net'
set :userid, ENV['GITHUB_USER'] || 'zzak'
set :repoid, ENV['GITHUB_REPO'] || 'blog.zacharyscott.net'
set :public_folder, File.dirname(__FILE__) + '/public'
set :views, File.dirname(__FILE__)

DataMapper.setup(:default, ENV['DATABASE_URL'])
class Post
  include DataMapper::Resource
  property :id,         Serial
  property :title,      String
  property :file,       String
  property :created_at, DateTime
  validates_uniqueness_of :file, :title
end
DataMapper.finalize
Post.auto_upgrade!

configure :production do
  sha1, date = `git log HEAD~1..HEAD --pretty=format:%h^%ci`.strip.split('^')

  require 'rack/cache'
  use Rack::Cache

  before do
    cache_control :public, :must_revalidate, :max_age=>300
    etag sha1
    last_modified date
  end
end

helpers do
  def escape_uri text
    return text.gsub('_',' ').gsub('.md', '')
  end

  def request_file file
    glorify(HTTParty.get("https://raw.github.com/#{settings.userid}/#{settings.repoid}/master/#{file}").to_s)
  end
end

before do
  @info = HTTParty.get("#{settings.base_uri}/repos/show/#{settings.userid}/#{settings.repoid}")
  @info["repository"]["homepage"].chomp!('/') if @info["repository"]["homepage"][-1,1] == '/'
  @user = HTTParty.get("#{settings.base_uri}/user/show/#{settings.userid}")
end

get '/' do
  @blobs = HTTParty.get("#{settings.base_uri}/blob/all/#{settings.userid}/#{settings.repoid}/master")["blobs"].map{|b|b[0]}.sort
  haml :index
end

get '/show/:post' do
  @post = glorify(HTTParty.get("https://raw.github.com/#{settings.userid}/#{settings.repoid}/master/#{params[:post]}").to_s)
  @history = HTTParty.get("#{settings.base_uri}/commits/list/#{settings.userid}/#{settings.repoid}/master/#{params[:post]}").to_hash
  haml :show
end

get '/feed' do
  @posts = Post.all(:order => [:id.desc], :limit => 20)
  builder :feed, :layout => false
end

post '/feed/:token' do
  push = JSON.parse(params[:payload])
  push['commits'].each do |commit|
    if commit['added'] && !commit['added'].empty?
      @post = Post.create(
        :title => escape_uri(commit['added'].first),
        :file => commit['added'].first,
        :created_at => commit['timestamp']
      ) if params[:token] == ENV['TOKEN']
    end
  end
end

get '/ga.js' do
  haml :ga, :layout => false
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
    %link{:rel=>"stylesheet", :href=>"/css/pygments.css", :type=>"text/css"}
    <link rel="alternate" type="application/rss+xml" title="RSS" href="/feed">
    %script{:type=>"text/javascript", :src=>"/ga.js"}
  %body
    #header
      = haml(:header, :layout=>false)
    #content
      #main
        = yield 
      #sidebar
        = haml(:sidebar, :layout=>false)
    = haml(:footer, :layout=>false)
    
@@feed
xml.instruct! :xml, :version => '1.0'
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @info["repository"]["name"]
    xml.description @info["repository"]["description"]
    xml.link @info["repository"]["url"]

    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.link "#{@info["repository"]["homepage"]}/show/#{post.file}"
        xml.description request_file(post.file)
        xml.pubDate Time.parse(post.created_at.to_s).rfc822()
        xml.guid "#{@info["repository"]["homepage"]}/show/#{post.file}"
      end
    end
  end
end

@@index
%ul.posts
  - @blobs.each do |b|
    %li
      %h1
        %a{:href=>"/show/#{b}"}= escape_uri b

@@header
%ul#blog_stats
  %li
    %a{:href=>"/feed"}
      %img{:src=>"/images/rss2.png"}
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
%h1#username
  = @user["user"]["name"]
  %a{:href=>"http://github.com/#{settings.userid}/followers"}
    %sup
      = @user["user"]["followers_count"]
      %img{:src=>"/images/watchers.png"}
%ul#user_stats
  %li
    %a{:href=>"mailto:#{@user["user"]["email"]}"}
      mail  
      %br 
      %img{:src=>"/images/mail.png"}
  %li
    %a{:href=>"http://github.com/#{@user["user"]["login"]}"}
      code  
      %br 
      %img{:src=>"/images/code.png"}
  %li
    %a{:href=>@user["user"]["blog"]}
      home  
      %br 
      %img{:src=>"/images/home.png"}
%img#avatar{:src=>"http://www.gravatar.com/avatar/#{@user["user"]["gravatar_id"]}"}

@@show
#post_info
  %h2 Author
  %p#author_name
    By
    %a{:href=>"http://github.com/#{@history["commits"][0]["author"]["login"]}"}
      = @history["commits"][0]["author"]["name"]
  %h2 Last Update
  %p#authored_date
    = Date.parse(@history["commits"][0]["authored_date"]).strftime("%A %B %d %Y at %I:%M%p")
  %h2#history_button History
  #history
    - @history["commits"].each do |commit|
      .commit
        %p.commit_message= commit["message"]
        %p.commit_date= Date.parse(commit["authored_date"]).strftime("%A %B %d %Y at %I:%M%p")
#post
  = @post

@@ga
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', '#{settings.ga_id}']);
  _gaq.push(['_setDomainName', '#{settings.ga_domain}']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

@@stylesheet
* 
  margin: 0
  padding: 0
  border: 0
  outline: 0 

body
  color: #000
  background-color: #FFFFFF
  font-family: "Lucida Grande", "Lucida Sans Unicode", "Garuda" 

a:link, a:visited 
  color: #000000

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
    text-align: right  
  ul 
    list-style-type: none
    margin-left: 20px
  #user_stats
    text-align: center
    line-height: 1em
    clear: both
    a
      text-decoration: none
    li
      float: right
      margin-right: 10px
  #avatar
    clear: both
    text-align: right
  #location
    clear: both

.page_header
  margin: 20px

.posts
  width: 700px
  margin: 0 auto
  li
    width: 210px
    float: left
    margin: 10px
    list-style-type: none
  h1
    font-size: 1em

#post_info
  float: right
  width: 25%
  background: #000000
  padding: 20px
  color: #FFFFFF
  a:link, a:visited
    color: #FFFFFF
  a:hover, a:active
    color: #8F8F8F
  h2
    text-align: right
    color: #8F8F8F
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
    overflow: auto
    overflow-Y: hidden
    margin-left: -60px
    font-size: 1.1em

#history_button
  cursor: pointer

#history
  line-height: 17px
  .commit
    margin-bottom: 10px
  .commit_date
    font-size: 12px
    color: #9F9F9F

#footer 
  clear: both
  text-align: center
  font-size: .8em 
 
