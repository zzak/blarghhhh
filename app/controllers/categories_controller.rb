class CategoriesController < ApplicationController

  # GET /categories/1
  # GET /categories/1.xml
  # Show all posts within given category  
  def show
    @categories = Category.find(:all)
    @category = Category.find_by_name(params[:id])
    page = params[:page] || 1
    @posts = Post.paginate :page => page, 
      :order => 'created_at DESC', 
      :conditions => {:published => true, :category_id => @category.id}, 
      :per_page => 10

    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
end
