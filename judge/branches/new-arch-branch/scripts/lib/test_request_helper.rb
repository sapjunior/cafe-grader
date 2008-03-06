module Grader

  class TestRequestRoomMaker
    def initialize
      @config = Grader::Configuration.get_instance
    end
    
    def produce_grading_room(test_request)
      problem_name = test_request.problem_name
      grading_room = "#{@config.user_result_dir}/" + 
        "#{user.login}/test_request/#{problem_name}/#{test_request.id}"
      
      FileUtils.mkdir_p(grading_room)
      grading_room
    end
    
    def find_problem_home(test_request)
      problem_name = test_request.problem_name
      
      # TODO
    end

    def save_source(test_request,source_name)
      dir = self.produce_grading_room(test_request)
      submission = test_request.submission
      f = File.open("#{dir}/#{source_name}","w")
      f.write(submission.source)
      f.close
    end
  end
  
  class TestRequestReporter
    def initialize
      @config = Grader::Configuration.get_instance
    end

    def report(test_request,test_result_dir)
      # TODO:
      save_result(test_request,read_result(test_result_dir))
    end

    protected
    def read_result(test_result_dir)
      # TODO:
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

end
