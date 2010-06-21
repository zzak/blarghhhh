class Comment < ActiveRecord::Base
  belongs_to :post
    
  validates_presence_of :name, :body

  acts_as_textiled :body

end
