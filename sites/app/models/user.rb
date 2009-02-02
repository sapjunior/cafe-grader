class User < ActiveRecord::Base

  belongs_to :country
  belongs_to :site

  before_create :assign_login

  def self.encode_id_by_country(country,num)
    if num > 9
      return "#{country.login.upcase}#{num}"
    else
      return "#{country.login.upcase}0#{num}"
    end
  end
  
  def self.encode_id_by_site(site,num)
    if num > 9
      return "#{site.login.upcase}#{num}"
    else
      return "#{site.login.upcase}0#{num}"
    end
  end

  def password
    self[:password] or '(to be assigned)'
  end

  protected 

  def assign_login
    return if self.country == nil
    return if self.login!=nil
    return if self.site == nil

    if PREFIX_LEVEL == :country
      country = self.country
      prefix_group = User.find(:all, 
                               :conditions => { :country_id => country.id })
    else
      site = self.site
      prefix_group = User.find(:all, 
                               :conditions => { :site_id => site.id })
    end
    last = 0
    prefix_group.each do |user|
      if user.login!=nil
        if res = /^([a-zA-Z])+((\d)+)$/.match(user.login)
          l = res[2].to_i
          last = l if l>last
        end
      end            
    end
    log_id = last+1
    if PREFIX_LEVEL == :country
      self.login = User.encode_id_by_country(country,log_id)
    else
      self.login = User.encode_id_by_site(site,log_id)
    end
  end

end
