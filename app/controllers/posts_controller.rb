class PostsController < ApplicationController

  # GET /posts
  # GET /posts.xml
  def index
    if params[:page].blank?
      page = 1
    else
      page = params[:page]
    end
    @posts = Post.paginate :page => page, 
      :order => 'created_at DESC', 
      :conditions => {:published => true}, 
      :per_page => 10
    #@posts = Post.find(:all, :conditions => {:published => true}, :order => 'created_at DESC')
    @categories = Category.find(:all)
    

    respond_to do |format|
      format.html # index.html.erb
      format.rss
    end
  end
  
  # GET /posts/1
  # GET /posts/1.xml
  def show
    @post = Post.find(params[:id])
    @categories = Category.find(:all)
    @comment = Comment.new(:post=>@post)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @post }
    end
  end
end
