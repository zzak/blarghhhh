require "haml"
require "sass"
require "httparty"
require "sinatra"
require "redcarpet"
require "albino"
require "nokogiri"

set :base_uri, 'http://github.com/api/v2/json'
set :ga_id, ENV['GA_ID'] || 'UA-26071793-1'
set :ga_domain, ENV['GA_DOMAIN'] || 'blog.zacharyscott.net'
set :userid, ENV['GITHUB_USER'] || 'zzak'
set :repoid, ENV['GITHUB_REPO'] || 'blog.zacharyscott.net'
set :public, File.dirname(__FILE__) + '/public'
set :views, File.dirname(__FILE__)

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

  def markdown text
   options = [:filter_html, :autolink,
      :no_intraemphasis, :fenced_code, :gh_blockcode]  
    syntax_highlighter(Redcarpet.new(text, *options).to_html)
  end 
  
  def syntax_highlighter html
    doc = Nokogiri::HTML(html) 
    doc.search("//pre[@lang]").each do |pre|  
      pre.replace colorize(pre.text.rstrip, pre[:lang])
    end 
    doc.search('pre').each do |pre|
      pre.children.each do |c|
        c.parent = pre.parent
      end
      pre.remove 
    end 
    doc.search('div').each do |div|
      if div['class'] == 'highlight'
       div.replace(Nokogiri.make("<pre>#{div.to_html}</pre>"))
      end
    end 
    doc.to_s 
  end

  def colorize(code, lang)
    if(can_pygmentize)
      Albino.colorize(code, lang)
    else
      Net::HTTP.post_form(URI.parse('http://pygments.appspot.com/'),
                          {'code'=>code, 'lang'=>lang}).body
    end
  end

  def can_pygmentize
    system 'pygmentize -V'
  end

end

before do
  @info = HTTParty.get("#{settings.base_uri}/repos/show/#{settings.userid}/#{settings.repoid}")
  @user = HTTParty.get("#{settings.base_uri}/user/show/#{settings.userid}")
end

get '/' do
  @blobs = HTTParty.get("#{settings.base_uri}/blob/all/#{settings.userid}/#{settings.repoid}/master")["blobs"].map{|b|b[0]}.sort
  haml :index
end

get '/show/:post' do
  @post = markdown(HTTParty.get("https://raw.github.com/#{settings.userid}/#{settings.repoid}/master/#{params[:post]}").to_s)
  @history = HTTParty.get("#{settings.base_uri}/commits/list/#{settings.userid}/#{settings.repoid}/master/#{params[:post]}").to_hash
  haml :show
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
    

@@index
%ul.posts
  - @blobs.each do |b|
    %li
      %h1
        %a{:href=>"/show/#{b}"}= escape_uri b

@@header
%ul#blog_stats
  %li
    %a{:href=>"https://github.com/#{settings.userid}/#{settings.repoid}/commits/master.atom"}
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
    = @history["commits"][0]["authored_date"].strftime("%A %B %d %Y at %I:%M%p")
  %h2#history_button History
  #history
    - @history["commits"].each do |commit|
      .commit
        %p.commit_message= commit["message"]
        %p.commit_date= commit["authored_date"].strftime("%A %B %d %Y at %I:%M%p")
#post
  = @post

@@ga
:javascript
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
  color: #000
  text-shadow: #2F2F2F 1px 1px 1px !important

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
  width: 500px

.posts li
  width: 200px
  float: left

.posts h1
  font-size: 1em

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
    color: #5F5F5F

#footer 
  clear: both
  text-align: center
  font-size: .8em 
 
