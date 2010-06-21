class Post < ActiveRecord::Base
  belongs_to :category
  has_many :comments, :dependent => :destroy, :order => 'created_at DESC'
    
  def to_param
    "#{id}-#{title.gsub(/[^a-z0-9]+/i, '-')}"
  end
    
end
