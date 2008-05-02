class SiteController < ApplicationController

  before_filter :check_user, :except => ['index','login']

  def index
    redirect_to :action => 'list'
  end

  def logout
    reset_session
    redirect_to :controller => 'login', :action => 'index'
  end

  def list
    @site = Site.find(session[:site_id])
    @users = @site.users
  end

  def add
    @site = Site.find(session[:site_id])
    @user = User.new(params[:user])
    @user.country = @site.country
    @user.site = @site
    if !@user.save
      flash[:notice] = "Error saving user"
      @users = @site.users
      render :action => 'list'
    else
      flash[:notice] = "Successfully added user"
      redirect_to :action => 'list'
    end
  end

  def delete
    user = User.find(params[:id])
    user.destroy
    redirect_to :action => 'list'
  end

  def edit
    @site = Site.find(session[:site_id])
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:site])
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def upload
    site = Site.find(session[:site_id])
    if params[:file]==''
      flash[:notice] = "Error: uploading no file!"
      redirect_to :action => 'list' and return
    end
    namestr = params[:file].read
    if namestr==nil
      flash[:notice] = "Error: uploading empty file!"
      redirect_to :action => 'list' and return
    end
    count = 0
    namestr.split(/$/).each do |name|
      name = name.chomp
      if name!=nil and name[0,1]=="\n"
        name = name[1,name.length-1]
      end
      if name!=''
        user = User.new({:name => name})
        user.site = site
        user.country = site.country
        user.save
        count += 1
      end
    end
    flash[:notice] = "Uploaded #{count} users"
    redirect_to :action => 'list'
  end

  protected

  def check_user
    if session[:site_id]==nil
      redirect_to :controller => 'login', :action => 'index'
    end
  end

end
