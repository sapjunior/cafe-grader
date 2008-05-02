class Country < ActiveRecord::Base

  has_many :sites, :dependent => :destroy
  has_many :users, :dependent => :destroy

  validates_presence_of :name
  validates_presence_of :login
  validates_presence_of :password
  #validates_presence_of :email

end
