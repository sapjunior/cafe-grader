#
# A grader engine grades a submission, against anything
#  -- a test data, or a user submitted test data
#

require 'fileutils'

module Grader

  # TODO: move to somewhere else
  class GradingRoomMaker
    def initialize
      @config = Grader::Configuration.get_instance
    end
    
    def produce_grading_room(submission,user,problem)
      grading_room = "#{@config.user_result_dir}/" + 
        "#{user.login}/#{problem.name}/#{submission.id}"
      
      FileUtils.mkdir_p(grading_room)
      grading_room
    end
    
    def find_problem_home(submission,problem)
      "#{@config.problems_dir}/#{problem.name}"
    end
  end
  
  # TODO: move to somewhere else
  class GradingReporter
    def initialize
      @config = Grader::Configuration.get_instance
    end

    def report(sub,test_result_dir)
      save_result(sub,read_result(test_result_dir))
    end

    protected
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
      problem = submission.problem
      submission.graded_at = Time.now
      points = result[:points]
      submission.points = points
      comment = @config.report_comment.call(result[:comment])
      if problem == nil
        submission.grader_comment = 'PASSED: ' + comment + '(problem is nil)'
      elsif points == problem.full_score
        submission.grader_comment = 'PASSED: ' + comment
      else
        submission.grader_comment = 'FAILED: ' + comment
      end
      submission.compiler_message = result[:cmp_msg]
      submission.save
    end
    
  end
  
  class Engine
    
    attr_writer :room_maker
    attr_writer :reporter

    def initialize(room_maker=nil, reporter=nil)
      @config = Grader::Configuration.get_instance

      if room_maker!=nil
        @room_maker = room_maker
      else
        @room_maker = Grader::GradingRoomMaker.new 
      end
        
      if reporter!=nil
        @reporter = reporter
      else
        @reporter = Grader::GradingReporter.new
      end
    end
    
    def grade(sub)
      current_dir = `pwd`.chomp

      user = sub.user
      problem = sub.problem

      # TODO: will have to create real exception for this
      raise "improper submission" if sub.user==nil
      
      language = sub.language.name
      lang_ext = sub.language.ext
      # FIX THIS
      talk 'some hack on language'
      if language == 'cpp'
        language = 'c++'
      end

      grading_dir = @room_maker.produce_grading_room(sub,user,problem)
      problem_home = @room_maker.find_problem_home(sub,problem)

      # puts "GRADING DIR: #{grading_dir}"
      # puts "PROBLEM DIR: #{problem_home}"

      # COMMENT: should it be only source.ext
      if problem!=nil
        source_name = "#{problem.name}.#{lang_ext}"
      else
        source_name = "source.#{lang_ext}"
      end
      
      save_source(sub,grading_dir,source_name)
      copy_log = copy_script(problem_home)
      
      call_judge(problem_home,language,grading_dir,source_name)

      @reporter.report(sub,"#{grading_dir}/test-result")

      clear_script(copy_log,problem_home)
      
      Dir.chdir(current_dir)
    end

    protected
    
    def talk(str)
      if @config.talkative
        puts str
      end
    end

    def save_source(submission,dir,fname)
      f = File.open("#{dir}/#{fname}","w")
      f.write(submission.source)
      f.close
    end

    def call_judge(problem_home,language,grading_dir,fname)
      ENV['PROBLEM_HOME'] = problem_home
      
      talk grading_dir
      Dir.chdir grading_dir
      cmd = "#{problem_home}/script/judge #{language} #{fname}"
      talk "CMD: #{cmd}"
      system(cmd)
    end

    def get_std_script_dir
      GRADER_ROOT + '/std-script'
    end

    def copy_script(problem_home)
      script_dir = "#{problem_home}/script"
      std_script_dir = get_std_script_dir

      raise "std-script directory not found" if !FileTest.exist?(std_script_dir)

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

    def mkdir_if_does_not_exist(dirname)
      Dir.mkdir(dirname) if !FileTest.exist?(dirname)
    end
    
  end
  
end
