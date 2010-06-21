class Category < ActiveRecord::Base
    has_many :posts, :conditions => {:published => true}, :dependent => :destroy, :order => 'created_at DESC'

    validates_presence_of :name
end
