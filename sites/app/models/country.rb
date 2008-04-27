class Country < ActiveRecord::Base

  has_many :sites
  has_many :users

  validates_presence_of :name
  validates_presence_of :login
  validates_presence_of :password
  validates_presence_of :email

end
