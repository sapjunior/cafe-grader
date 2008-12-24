# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  SYSTEM_MODE_CONF_KEY = 'system.mode'

  def user_header
    menu_items = ''
    user = User.find(session[:user_id])

    if (user!=nil) and (session[:admin]) 
      # admin menu
      menu_items << "<b>Administrative task:</b> "
      append_to menu_items, '[Announcements]', 'announcements', 'index'
      append_to menu_items, '[Msg console]', 'messages', 'console'
      append_to menu_items, '[Problem admin]', 'problems', 'index'
      append_to menu_items, '[User admin]', 'user_admin', 'index'
      append_to menu_items, '[Results]', 'user_admin', 'user_stat'
      append_to menu_items, '[Graders]', 'graders', 'list'
      append_to menu_items, '[Sites]', 'sites', 'index'
      append_to menu_items, '[System config]', 'configurations', 'index'
      menu_items << "<br/>"
    end

    # main page
    append_to menu_items, "[#{I18n.t 'menu.main'}]", 'main', 'list'
    append_to menu_items, "[#{I18n.t 'menu.messages'}]", 'messages', 'list'

    if (user!=nil) and (Configuration.show_tasks_to?(user))
      append_to menu_items, "[#{I18n.t 'menu.tasks'}]", 'tasks', 'list'
      append_to menu_items, "[#{I18n.t 'menu.submissions'}]", 'main', 'submission'
      append_to menu_items, "[#{I18n.t 'menu.test'}]", 'test', 'index'
    end
    append_to menu_items, "[#{I18n.t 'menu.help'}]", 'main', 'help'

    if Configuration['system.user_setting_enabled']
      append_to menu_items, "[#{I18n.t 'menu.settings'}]", 'users', 'index'
    end
    append_to menu_items, "[#{I18n.t 'menu.log_out'}]", 'main', 'login'

    menu_items
  end

  def append_to(option,label, controller, action)
    option << ' ' if option!=''
    option << link_to_unless_current(label,
                                     :controller => controller,
                                     :action => action)
  end

  def format_short_time(time)
    now = Time.now.gmtime
    st = ''
    if (time.yday != now.yday) or
	(time.year != now.year)
      st = time.strftime("%x ")
    end
    st + time.strftime("%X")
  end

  def read_textfile(fname,max_size=2048)
    begin
      File.open(fname).read(max_size)
    rescue
      nil
    end
  end

  def user_title_bar(user)
    header = ''
    time_left = ''

    #
    # if the contest is over
    if Configuration[SYSTEM_MODE_CONF_KEY]=='contest' 
      if user.site!=nil and user.site.finished?
        header = <<CONTEST_OVER
<tr><td colspan="2" align="center">
<span class="contest-over-msg">THE CONTEST IS OVER</span>
</td></tr>
CONTEST_OVER
      end
      if !user.site.started
        time_left = "&nbsp;&nbsp;" + (t 'title_bar.contest_not_started')
      else
        if user.site!=nil
          time_left = "&nbsp;&nbsp;" + (t 'title_bar.remaining_time') + 
            " #{Time.at(user.site.time_left).gmtime.strftime("%X")}"
        end
      end
    end
    
    #
    # if the contest is in the anaysis mode
    if Configuration[SYSTEM_MODE_CONF_KEY]=='analysis'
      header = <<ANALYSISMODE
<tr><td colspan="2" align="center">
<span class="contest-over-msg">ANALYSIS MODE</span>
</td></tr>
ANALYSISMODE
    end

    contest_name = Configuration['contest.name']

    #
    # build real title bar
    <<TITLEBAR
<div class="title">
<table>
#{header}
<tr>
<td class="left-col">
#{user.full_name}<br/>
#{t 'title_bar.current_time'} #{format_short_time(Time.new)}
#{time_left}
<br/>
</td>
<td class="right-col">#{contest_name}</td>
</tr>
</table>
</div>
TITLEBAR
  end

end
