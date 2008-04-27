class User < ActiveRecord::Base

  belongs_to :country
  belongs_to :site

  before_create :assign_login

  protected 
  def assign_login
    return if self.country == nil
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
    if log_id > 100
      self.login = "#{country.login.upcase}#{log_id}"
    elsif log_id > 9
      self.login = "#{country.login.upcase}#{log_id}"
    else
      self.login = "#{country.login.upcase}0#{log_id}"
    end
  end

end
