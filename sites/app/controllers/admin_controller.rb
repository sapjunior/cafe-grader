require 'tempfile'
require 'yaml'

class AdminController < ApplicationController

  before_filter :check_user, :except => ['index','login']

  verify :method => :post, 
         :only => ['create', 'import_country', 'import_data', 'update', 'gen_passwd'], 
         :redirect_to => {:action => 'list'}

  #
  # In and out
  #

  def index
    reset_session
  end

  def login
    if params[:login][:user_name]=="" and 
        params[:login][:password]=="thailander"  # should change this
      session[:user]='admin'
      redirect_to :action => 'list'
    else
      redirect_to :action => 'index'
    end
  end

  def logout
    reset_session
    redirect_to :controller => 'login', :action => 'index'
  end

  #
  # Country management
  #

  def list
    @countries = Country.find(:all)
  end

  def new
    @country = Country.new
  end

  def create
    @country = Country.new(params[:country])
    if !@country.save
      render :action => 'new'
    else
      redirect_to :action => 'list'
    end
  end

  def delete
    country = Country.find(params[:id])
    country.destroy
    redirect_to :action => 'list'
  end

  def edit
    @country = Country.find(params[:id])
  end

  def update
    @country = Country.find(params[:id])
    if @country.update_attributes(params[:country])
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def upload
  end

  def import_country
    import_country_list
  end

  #
  # User information
  #

  def import
  end

  def import_data
    if params[:file]==''
      flash[:notice] = 'Error importing no file'
      redirect_to :action => 'list' and return
    end
    import_from_file(params[:file])
  end

  def export
    export_data
  end

  def users
    @countries = Country.find(:all)
  end

  def passwd
  end

  def gen_passwd
    if params[:passwd][:key]!='I am sure'
      flash[:notice] = 'Wrong key'
      render :action => 'passwd' and return
    end
    if params[:passwd][:option] == 'unassigned'
      users = User.find(:all, :conditions => 'ISNULL(password)')
    else
      users = User.find(:all)
    end
    users.each do |user|
      user.password = random_password
      user.save
    end
    flash[:notice] = 'Password generation successful'
    redirect_to :action => 'list'
  end

  ######################################
  # Implementation 

  protected

  def random_password(length=5)
    chars = 'abcdefghjkmnopqrstuvwxyz'
    password = ''
    length.times { password << chars[rand(chars.length - 1)] }
    password
  end

  def build_hash_from_collection(collection, name_attrs, attrs)
    h = {}
    collection.each do |obj|
      this_hash = {}
      attrs.each do |attr|
        this_hash[attr] = obj.send(attr)
      end
      h[obj.send(name_attrs)] = this_hash
    end
    h
  end

  def check_user
    if session[:user]!='admin'
      redirect_to :action => 'index'
    end
  end

  def export_data
    countries = Country.find(:all)
    sites = Site.find(:all)
    users = User.find(:all)

    country_hash = build_hash_from_collection(countries,:id,
                                              [:name])
    site_hash = build_hash_from_collection(sites,:id,
                                           [:name,:password,:country_id])
    user_hash = build_hash_from_collection(users,:id,
                                           [:login,:name,:password,:site_id,:country_id])
    
    all_hash = {
      :countries => country_hash, 
      :sites => site_hash,
      :users => user_hash
    }
    tf = Tempfile.new("site")
    YAML.dump(all_hash,tf)
    tf.close
    send_file tf.path, :filename => 'data.yml', :type => 'text/plain'
  end

  def import_country_list
    if params[:file]==''
      flash[:notice] = "Error: uploading no file!"
      redirect_to :action => 'upload' and return
    end
    country_list_str = params[:file].read
    if country_list_str==nil
      flash[:notice] = "Error: uploading empty file!"
      redirect_to :action => 'upload' and return
    end
    count = 0
    country_list_str.split(/$/).each do |country_str|
      country_str = country_str.chomp
      if country_str[0,1]=="\n"
        country_str = country_str[1,country_str.length-1]
      end
      if country_str!=''
        items = country_str.split(':')
        country = Country.new
        country.name = items[0]
        country.login = items[1]
        country.password = items[2]
        country.email = items[3]
        country.save
      end
    end
    flash[:notice] = "Uploaded #{count} countries"
    redirect_to :action => 'list'
  end

  def import_from_file(f)
    data_hash = YAML.load(f)
    @import_log = ""
    
    country_data = data_hash[:countries]
    site_data = data_hash[:sites]
    user_data = data_hash[:users]
    
    # import country
    countries = {}
    country_data.each_pair do |id,country|
      c = Country.find_by_name(country[:name])
      if c!=nil
        countries[id] = c
        @import_log << "Found #{country[:name]}\n"
      else
        @import_log << "#{country[:name]} NOT FOUND\n"
      end
    end

    # import sites
    sites = {}
    site_data.each_pair do |id,site|
      s = Site.find_by_name(site[:name])
      if s!=nil
        @import_log << "Found #{site[:name]}\n"
      else
        s = Site.new(:name => site[:name])
        @import_log << "Created #{site[:name]}\n"
      end
      s.password = site[:password]
      s.country = countries[site[:country_id]]

      if s.country==nil
        @import_log << "Error country not found\n"
      else
        s.save
        sites[id] = s
      end
    end

    # import users
    user_data.each_pair do |id,user|
      u = User.find_by_login(user[:login])
      if u!=nil
        @import_log << "Found #{user[:login]}\n"
      else
        u = User.new(:login => user[:login])
        @import_log << "Created #{user[:login]}\n"
      end
      u.name = user[:name]
      u.password = user[:password]
      u.country = countries[user[:country_id]]
      u.site = sites[user[:site_id]]
      if u.site==nil
        @import_log << "Error country/site not found\n"
      else
        u.save
      end
    end

  end

end
