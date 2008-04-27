class LoginController < ApplicationController

  def index
    @countries = Country.find(:all)
  end

  def site_list
    if params[:site]!=nil
      @country = Country.find(params[:site][:country_id])
    else
      @country = Country.find_by_name(params[:id])
    end
    @sites = @country.sites
  end

  def site_login
    site = Site.find(params[:login][:site_id])
    if site==nil
      flash[:notice] = 'Wrong site'
      redirect_to :action => 'index'  and return
    end
    if site.password == params[:login][:password]
      session[:site_id] = site.id
      redirect_to :controller => 'site', :action => 'list'
    else
      flash[:notice] = 'Wrong site password'
      redirect_to :action => 'site_list', :id => site.country.name
    end
  end

  def country_login
    country = Country.find_by_login(params[:country][:login])
    if country==nil
      flash[:notice] = 'Wrong username'
      redirect_to :action => 'index' and return
    end
    if params[:country][:password]==country.password
      session[:country_id]=country.id
      redirect_to :controller => 'country', :action => 'list'
    else
      flash[:notice] = 'Wrong password'
      redirect_to :action => 'index'
    end
  end

end
