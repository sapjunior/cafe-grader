class AdminController < ApplicationController

  before_filter :check_user, :except => ['index','login']

  def index
    reset_session
  end

  def login
    if params[:login][:password]=="thailander"  # should change this
      session[:user]='admin'
      redirect_to :action => 'list'
    else
      redirect_to :action => 'index'
    end
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

  protected

  def check_user
    if session[:user]!='admin'
      redirect_to :action => 'index'
    end
  end

end
