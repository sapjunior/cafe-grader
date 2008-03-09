require 'fileutils'

module Grader

  #
  # A grader engine grades a submission, against anything: a test
  # data, or a user submitted test data.  It uses two helpers objects:
  # room_maker and reporter.
  #
  class Engine
    
    attr_writer :room_maker
    attr_writer :reporter

    def initialize(room_maker=nil, reporter=nil)
      @config = Grader::Configuration.get_instance

      @room_maker = room_maker || Grader::SubmissionRoomMaker.new 
      @reporter = reporter || Grader::SubmissionReporter.new
    end
    
    # takes a submission, asks room_maker to produce grading directories,
    # calls grader scripts, and asks reporter to save the result
    def grade(submission)
      current_dir = `pwd`.chomp

      user = submission.user
      problem = submission.problem

      # TODO: will have to create real exception for this
      raise "improper submission" if submission.user==nil
      
      language = submission.language.name
      lang_ext = submission.language.ext
      # FIX THIS
      talk 'some hack on language'
      if language == 'cpp'
        language = 'c++'
      end

      # COMMENT: should it be only source.ext?
      if problem!=nil
        source_name = "#{problem.name}.#{lang_ext}"
      else
        source_name = "source.#{lang_ext}"
      end

      begin
        grading_dir = @room_maker.produce_grading_room(submission)
        @room_maker.save_source(submission,source_name)
        problem_home = @room_maker.find_problem_home(submission)

        # puts "GRADING DIR: #{grading_dir}"
        # puts "PROBLEM DIR: #{problem_home}"

        copy_log = copy_script(problem_home)
      
        call_judge(problem_home,language,grading_dir,source_name)

        @reporter.report(submission,"#{grading_dir}/test-result")

        clear_script(copy_log,problem_home)

      rescue RuntimeError => msg
        @reporter.report_error(submission,"Grading error: #{msg}")

      ensure
        @room_maker.clean_up(submission)
        Dir.chdir(current_dir)   # this is really important
      end
    end
    
    protected
    
    def talk(str)
      if @config.talkative
        puts str
      end
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
