class LoginController < ApplicationController

  def index
    countries = Country.find(:all)
    @country_select = countries.collect { |c| [c.name, c.id] }

    @site_select = []
    countries.each do |country|
      country.sites.each do |site|
        @site_select << ["#{site.name},#{country.name}", site.id]
      end
    end
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
    country = Country.find(params[:country][:id])
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
