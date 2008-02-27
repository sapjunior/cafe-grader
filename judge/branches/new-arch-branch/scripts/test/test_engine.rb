require 'test/unit'
require 'rubygems'
require 'mocha'

require File.join(File.dirname(__FILE__),'test_helper')

class TestGraderEngine < UnitTest.TestCase

  def setup
    @@lang_c = stub(:name => 'c', :ext => 'c')
    @@lang_cpp = stub(:name => 'cpp', :ext => 'cpp')
    @@lang_pas = stub(:name => 'pas', :ext => 'pas')

    @config = Grader::Configuration.get_instance

    @problem_test1 = stub(:id => 1, :name => 'test1', :full_score => 135)
    @user_user1 = stub(:id => 1, :login => 'user1')

    @engine = Grader::Engine.new    

    clear_user_result_dir
  end

  def teardown
  end

  def test_grade_oldest_task_with_no_submission
    Task.expects(:get_inqueue_and_change_status).returns(nil)
    assert_equal nil, @engine.grade_oldest_task, 'should return nil when there is no task'
  end

  def test_normal_submission
    submission = create_test1_submission_mock_for_grading

    submission.expects(:graded_at=)
    submission.expects(:points=).with(135)
    submission.expects(:grader_comment=).with do |value|
      /^PASSED/.match(value)
    end
    submission.expects(:compiler_message=).with('')
    submission.expects(:save)

    @engine.grade(submission)
  end

  protected

  def clear_all_submissions
    Submission.find(:all).each do |submission|
      submission.destroy
    end
  end

  def clear_user_result_dir
    clear_cmd = "rm -rf #{@config.user_result_dir}/*"
    system(clear_cmd)
  end

  def create_submission_from_file(id, user, problem, source_fname, language = @@lang_c)
    source = File.open(@config.test_data_dir + "/" + source_fname).read
    stub(:id => id, :user => user, :problem => problem,
         :source => source, :language => language)
  end

  def create_test1_submission_mock_for_grading
    create_submission_from_file(1, @user_user1, @problem_test1, "test1_correct.c")
  end
  
end
