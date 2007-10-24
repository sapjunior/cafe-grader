module MainHelper

  def user_options
    options = ''
    user = User.find(session[:user_id])
    if user.admin? 
      options = options + ' ' +
	link_to('[Problem admin]', 
		{:controller => 'problems', :action => 'index'})
      options = options + ' ' +
	link_to('[User admin]',
		{:controller => 'user_admin', :action => 'index'})
    end
    options = options + ' ' +
      link_to('[Log out]', {:controller => 'main', :action => 'login'})
    options
  end

  def format_short_time(time)
    now = Time.now
    st = ''
    if (time.yday != now.yday) or
	(time.year != now.year)
      st = time.strftime("%x")
    end
    st + time.strftime("%X")
  end

  def format_compiler_msg(sub)
    <<cmpmsg
<div>
<div><a href="#" onClick="n = this.parentNode.parentNode.lastChild;
if(n.style.display == 'none') { n.style.display = 'block'; }
else {n.style.display ='none'; } return false;">
Compiler message</a> (click to see)</div>
<div style="display: none">
<div class="compilermsgbody" style="border: thin solid grey; margin: 2px">
#{h(sub.compiler_message).gsub(/\n/,'<br/>')}
</div>
</div></div>
cmpmsg
  end

  def format_submission(sub, count)
    msg = "#{count} submission(s)<br />"
    if count>0
      msg = msg + "Last on " +
	format_short_time(sub.submitted_at) + ' ' +
	link_to('[source]',{:action => 'get_source', :id => sub.id}) +
	"<br />"
    end
    if sub!=nil and sub.graded_at!=nil
      msg = msg + 'Graded at ' + format_short_time(sub.graded_at) + ', score: '+ 
        sub.points.to_s + 
	' [' + sub.grader_comment + "]<br />" +
	format_compiler_msg(sub)
    end
    msg 
  end

end
