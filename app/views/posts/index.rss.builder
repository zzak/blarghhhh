xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "blarghhhh"
    xml.description ""
    xml.link url_for(:controller=>'posts', :only_path=>false)
    
    for post in @posts
      xml.item do
        xml.title post.title
        xml.description post.body
        xml.pubDate post.created_at.to_s(:rfc822)
        xml.link url_for(:controller=>'posts', :action=>'show', :id=>post, :only_path => false)
      end
    end
  end
end
