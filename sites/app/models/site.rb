class Site < ActiveRecord::Base

  belongs_to :country
  has_many :users

  validates_presence_of :name
  validates_presence_of :password

end
