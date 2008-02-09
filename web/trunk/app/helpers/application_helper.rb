# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def user_header
    options = ''
    user = User.find(session[:user_id])

    # main page
    options += link_to_unless_current '[Main]',
                 :controller => 'main', :action => 'list'
    options += ' '

    # admin menu
    if user.admin? 
      options +=
	(link_to_unless_current '[Problem admin]', 
           :controller => 'problems', :action => 'index') + ' '
      options += 
	(link_to_unless_current '[User admin]',
           :controller => 'user_admin', :action => 'index') + ' '
      options += 
	(link_to_unless_current '[User stat]',
           :controller => 'user_admin', :action => 'user_stat') + ' '
    end

    # general options
    options += link_to_unless_current '[Settings]',
                 :controller => 'users', :action => 'index'
    options += ' '
    options += 
      link_to('[Log out]', {:controller => 'main', :action => 'login'})
    options
  end

end
