class CountryController < ApplicationController

  before_filter :check_user, :except => ['index','login']

  def index
    redirect_to :action => 'list'
  end

  def logout
    reset_session
    redirect_to :controller => 'login', :action => 'index'
  end

  def list
    @country = Country.find(session[:country_id])
    @sites = @country.sites
  end

  def create
    @country = Country.find(session[:country_id])
    @sites = @country.sites
    @site = Site.new(params[:site])
    @site.country = @country
    if !@site.save
      render :action => 'list'
    else
      redirect_to :action => 'list'
    end
  end

  def delete
    site = Site.find(params[:id])
    site.destroy
    redirect_to :action => 'list'
  end

  def edit
    @site = Site.find(params[:id])
  end

  def update
    @site = Site.find(params[:id])
    if @site.update_attributes(params[:site])
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  protected

  def check_user
    if session[:country_id]==nil
      redirect_to :controller => 'login', :action => 'index'
    end
  end

end
