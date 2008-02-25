
module Grader

  class Engine

    def initialize(grader_process=nil)
      @config = Grader::Configuration.get_instance
      @grader_process = grader_process
    end

    def grade(submission_id)
      current_dir = `pwd`.chomp
      
      sub = Submission.find(submission_id)
      user = sub.user
      problem = sub.problem
      
      language = sub.language.name
      lang_ext = sub.language.ext
      # FIX THIS
      talk 'some hack on language'
      if language == 'cpp'
        language = 'c++'
      end

      user_dir = "#{@config.user_result_dir}/#{user.login}"
      Dir.mkdir(user_dir) if !FileTest.exist?(user_dir)
      
      problem_out_dir = "#{user_dir}/#{problem.name}/#{submission_id}"
      Dir.mkdir(problem_out_dir) if !FileTest.exist?(problem_out_dir)
      
      problem_home = "#{@config.problems_dir}/#{problem.name}"
      source_name = "#{problem.name}.#{lang_ext}"
      
      save_source(sub,problem_out_dir,source_name)
      
      copy_log = copy_script(problem_home)
      
      call_judge(problem_home,language,problem_out_dir,source_name)
      save_result(sub,read_result("#{problem_out_dir}/test-result"))
      
      clear_script(copy_log,problem_home)
      
      Dir.chdir(current_dir)
    end

    def grade_oldest_task
      task = Task.get_inqueue_and_change_status(Task::STATUS_GRADING)
      if task!=nil 
        @grader_process.report_active(task) if @grader_process!=nil
    
        grade(task.submission_id)
        task.status_complete!
      end
      return task
    end

    def grade_problem(problem)
      users = User.find(:all)
      users.each do |u|
        puts "user: #{u.login}"
        last_sub = Submission.find(:first,
                                   :conditions => "user_id = #{u.id} and " +
                                                  "problem_id = #{prob.id}",
                                   :order => 'submitted_at DESC')
        if last_sub!=nil
          grade(last_sub.id)
        end
      end
    end

    protected
    
    def talk(str)
      if @config.talkative
        puts str
      end
    end

    def execute(command, error_message="")
      if not system(command)
        puts "ERROR: #{error_message}"
        exit(127)
      end
    end

    def save_source(submission,dir,fname)
      f = File.open("#{dir}/#{fname}","w")
      f.write(submission.source)
      f.close
    end

    def call_judge(problem_home,language,problem_out_dir,fname)
      ENV['PROBLEM_HOME'] = problem_home
      
      puts problem_out_dir
      Dir.chdir problem_out_dir
      cmd = "#{problem_home}/script/judge #{language} #{fname}"
      #  puts "CMD: #{cmd}"
      system(cmd)
    end

    def read_result(test_result_dir)
      cmp_msg_fname = "#{test_result_dir}/compiler_message"
      cmp_file = File.open(cmp_msg_fname)
      cmp_msg = cmp_file.read
      cmp_file.close
      
      result_fname = "#{test_result_dir}/result"
      comment_fname = "#{test_result_dir}/comment"  
      if FileTest.exist?(result_fname)
        result_file = File.open(result_fname)
        result = result_file.readline.to_i
        result_file.close
        
        comment_file = File.open(comment_fname)
        comment = comment_file.readline.chomp
        comment_file.close
        
        return {:points => result, 
          :comment => comment, 
          :cmp_msg => cmp_msg}
      else
        return {:points => 0,
          :comment => 'compile error',
          :cmp_msg => cmp_msg}
      end
    end
    
    def save_result(submission,result)
      problem = Problem.find(submission.problem_id)
      submission.graded_at = Time.now
      submission.points = result[:points]
      if submission.points == problem.full_score
        submission.grader_comment = 'PASSED: ' + @config.report_comment.call(result[:comment])
      else
        submission.grader_comment = 'FAILED: ' + @config.report_comment.call(result[:comment])
      end
      submission.compiler_message = result[:cmp_msg]
      submission.save
    end
    
    def copy_script(problem_home)
      script_dir = "#{problem_home}/script"
      std_script_dir = File.dirname(__FILE__) + '/std-script'
      scripts = Dir[std_script_dir + '/*']
      
      copied = []

      scripts.each do |s|
        fname = File.basename(s)
        if !FileTest.exist?("#{script_dir}/#{fname}")
          copied << fname
          system("cp #{s} #{script_dir}")
        end
      end
      
      return copied
    end
    
    def clear_script(log,problem_home)
      log.each do |s|
        system("rm #{problem_home}/script/#{s}")
      end
    end
    
  end
  
end
