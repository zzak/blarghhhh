class AdminController < ApplicationController
  
  before_filter :authenticate

  # show the main admin control panel
  def index

    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
  ######################################################
  #
  #                         POSTS
  #
  ######################################################
  
  # list posts
  def show_posts
    @posts = Post.find(:all, :order=>'created_at DESC')
    @categories = Category.find(:all)
    
  end
  
  def show_post
    @post = Post.find(params[:id])
  end

  # new post form
  def new_post
    @post = Post.new
    @categories = Category.find(:all)
    
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # edit an existing post
  def edit_post
    @post = Post.find(params[:id])
    @categories = Category.find(:all)
  end

  # create a new post
  def create_post
    @post = Post.new(params[:post])
    @categories = Category.find(:all)
    
    respond_to do |format|
      if @post.save
        flash[:notice] = 'Post was successfully created.'
        format.html { redirect_to(:controller=>'admin', :action=>'show_posts') }
      else
        flash[:notice] = 'Post creation has failed..'
        format.html { render :action => "new_post" }
      end
    end
  end

  # update an existing post
  def update_post
    @post = Post.find(params[:id])
    @categories = Category.find(:all)
    
    respond_to do |format|
      if @post.update_attributes(params[:post])
        flash[:notice] = 'Post was successfully updated.'
        format.html { redirect_to(:controller=>'admin', :action=>'show_post', :id=>@post.id) }
      else
        flash[:notice] = 'Post update has failed..'
        format.html { render :action => "edit_post", :id=>@post.id }
      end
    end
  end

  # delete an existing post
  def destroy_post
    @post = Post.find(params[:id])
    @post.destroy
    
    @categories = Category.find(:all)

    respond_to do |format|
      flash[:notice] = 'Post was successfully deleted.'
      format.html { redirect_to(:controller => 'admin', :action=>'show_posts') }
    end
  end
  
  ###########################################
  #
  #               CATEGORIES
  #
  ###########################################
  
  # show all categories
  def show_categories
    @categories = Category.find(:all, :order=>'created_at DESC')

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # show posts within a given category
  def show_category
    @category = Category.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # new category form
  def new_category
    @category = Category.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # edit an existing category
  def edit_category
    @category = Category.find(params[:id])
  end

  # create a new category
  def create_category
    @category = Category.new(params[:category])

    respond_to do |format|
      if @category.save
        flash[:notice] = 'Category was successfully created.'
        format.html { redirect_to( :action=>'show_categories' ) }
      else
        flash[:notice] = 'Category failed to save..'
        format.html { render :action => "new_category" }
      end
    end
  end

  # update an existing category
  def update_category
    @category = Category.find(params[:id])

    respond_to do |format|
      if @category.update_attributes(params[:category])
        flash[:notice] = 'Category was successfully updated.'
        format.html { redirect_to( :action=>'show_category', :id=>@category.id ) }
      else
        format.html { render :action => "edit_category", :id=>@category.id }
      end
    end
  end

  # destroy an existing category
  def destroy_category
    @category = Category.find(params[:id])
    @category.destroy

    respond_to do |format|
      flash[:notice] = 'Category was successfully deleted.'
      format.html { redirect_to( :action=>'show_categories' ) }
    end
  end
  
  #######################################################
  #
  #                       COMMENTS
  #
  #######################################################
  
  # GET /comments
  # GET /comments.xml
  # show all comments
  def show_comments
    @comments = Comment.find(:all, :order=>'created_at DESC')

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /comments/1
  # GET /comments/1.xml
  # show a given comment
  def show_comment
    @comment = Comment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
  # GET /comments/1/edit
  def edit_comment
    @comment = Comment.find(params[:id])
  end
  
  # PUT /comments/1
  # PUT /comments/1.xml
  def update_comment
    @comment = Comment.find(params[:id])

    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        flash[:notice] = 'Comment was successfully updated.'
        format.html { redirect_to( :action=>'show_comment', :id=>@comment.id ) }
      else
        flash[:notice] = 'Comment was not saved..'
        format.html { render :action => "edit_comment", :id=>@comment.id }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy_comment
    @comment = Comment.find(params[:id])
    @comment.destroy

    respond_to do |format|
      flash[:notice] = 'Comment was successfully deleted.'
      format.html { redirect_to( :action=>'show_comments' ) }
    end
  end
  
  protected
  
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == "admin" && password == "password"  
    end
  end
  
end
