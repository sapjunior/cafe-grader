class User < ActiveRecord::Base

  belongs_to :country
  belongs_to :site

  before_create :assign_login

  def self.encode_id(country,num)
    if num > 9
      return "#{country.login.upcase}#{num}"
    else
      return "#{country.login.upcase}0#{num}"
    end
  end

  def password
    self[:password] or '(to be assigned)'
  end

  protected 

  def assign_login
    return if self.country == nil
    return if self.login!=nil
    country = self.country
    country_users = User.find(:all, 
                              :conditions => { :country_id => country.id })
    last = 0
    country_users.each do |user|
      if user.login!=nil
        if res = /^([a-zA-Z])+((\d)+)$/.match(user.login)
          l = res[2].to_i
          last = l if l>last
        end
      end            
    end
    log_id = last+1
    self.login = User.encode_id(country,log_id)
  end

end
