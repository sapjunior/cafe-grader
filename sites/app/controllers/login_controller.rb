class LoginController < ApplicationController

  def index
    @countries = Country.find(:all)
    @country_select = @countries.collect { |c| [c.name, c.id] }

    @country_select_with_all = [['Any',0]]
    @countries.each do |country|
      @country_select_with_all << [country.name, country.id]
    end

    @site_select = []
    @countries.each do |country|
      country.sites.each do |site|
        @site_select << ["#{site.name}, #{country.name}", site.id]
      end
    end
  end

  def site_login
    begin
      site = Site.find(params[:login][:site_id])
    rescue ActiveRecord::RecordNotFound
      site = nil
    end
    if site==nil
      flash[:notice] = 'Wrong site'
      redirect_to :action => 'index'  and return
    end
    if site.password == params[:login][:password]
      session[:site_id] = site.id
      redirect_to :controller => 'site', :action => 'list'
    else
      flash[:notice] = 'Wrong site password'
      redirect_to :action => 'index'
    end
  end

  def country_login
    begin
      country = Country.find(params[:country][:id])
    rescue ActiveRecord::RecordNotFound
      country = nil
    end
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
