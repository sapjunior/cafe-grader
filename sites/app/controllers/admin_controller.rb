require 'tempfile'
require 'yaml'

class AdminController < ApplicationController

  before_filter :check_user, :except => ['index','login']

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

  def export
    countries = Country.find(:all)
    sites = Site.find(:all)
    users = User.find(:all)

    country_hash = build_hash_from_collection(countries,:id,
                                              [:name])
    site_hash = build_hash_from_collection(sites,:id,
                                           [:name,:country_id])
    user_hash = build_hash_from_collection(users,:id,
                                           [:login,:name,:site_id,:country_id])
    
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

  def upload
  end

  def import
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

  protected

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

end
