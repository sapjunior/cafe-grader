class Site < ActiveRecord::Base

  belongs_to :country
  has_many :users, :dependent => :destroy

  validates_presence_of :name
  validates_presence_of :password

end
