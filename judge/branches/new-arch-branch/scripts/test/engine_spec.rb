#require 'test/unit'
#require 'rubygems'
#require 'mocha'

require File.join(File.dirname(__FILE__),'spec_helper')

describe "A grader engine" do

  before(:each) do
    @@lang_c = stub(Language, :name => 'c', :ext => 'c')
    @@lang_cpp = stub(Language, :name => 'cpp', :ext => 'cpp')
    @@lang_pas = stub(Language, :name => 'pas', :ext => 'pas')

    @config = Grader::Configuration.get_instance

    @problem_test1 = stub(Problem,
                          :id => 1, :name => 'test1', :full_score => 135)
    @user_user1 = stub(User,
                       :id => 1, :login => 'user1')

    @engine = Grader::Engine.new    

    init_sandbox
  end

  it "should grade normal submission" do
    submission = create_test1_submission_mock_from_file("test1_correct.c")

    submission.should_receive(:graded_at=)
    submission.should_receive(:points=).with(135)
    submission.should_receive(:grader_comment=).with(/^PASSED/)
    submission.should_receive(:compiler_message=).with('')
    submission.should_receive(:save)

    @engine.grade(submission)
  end
  

  it "should just return nil when there is no submission" do
    Task.should_receive(:get_inqueue_and_change_status).and_return(nil)
    @engine.grade_oldest_task.should be_nil
  end

  it "should produce error message when submission cannot compile" do
    submission = create_test1_submission_mock_from_file("test1_compile_error.c")

    submission.should_receive(:graded_at=)
    submission.should_receive(:points=).with(0)
    submission.should_receive(:grader_comment=).with('FAILED: compile error')
    submission.should_receive(:compiler_message=).with(/[Ee]rror/)
    submission.should_receive(:save)

    @engine.grade(submission)
  end

  it "should produce timeout error when submission runs forever" do
    @problem_test2 = stub(Problem,
                          :id => 1, :name => 'test2', :full_score => 10)
    @user_user1 = stub(User,:id => 1, :login => 'user1')

    submission = create_submission_from_file(1, @user_user1, @problem_test2,
                                             "test2_timeout.c")

    submission.should_receive(:graded_at=)
    submission.should_receive(:points=).with(0)
    submission.should_receive(:grader_comment=).with(/^FAILED: TT$/)
    submission.should_receive(:compiler_message=).with('')
    submission.should_receive(:save)

    @engine.grade(submission)
  end

  it "should produce timeout error correctly when submission runs slower than expected in less than a second" do
    @problem_test2 = stub(Problem,
                          :id => 1, :name => 'test2', :full_score => 20)
    @user_user1 = stub(User,
                       :id => 1, :login => 'user1')

    submission = create_submission_from_file(1, @user_user1, @problem_test2,
                                             "test2_1-5sec.c")

    submission.should_receive(:graded_at=)
    submission.should_receive(:points=).with(10)
    submission.should_receive(:grader_comment=).with(/^FAILED: TP$/)
    submission.should_receive(:compiler_message=).with('')
    submission.should_receive(:save)

    @engine.grade(submission)
  end

  it "should produce runtime error when submission uses too much memory" do
    violated("to be implemented")
  end

  def test_grade_oldest_task
    # mock submission
    submission = create_test1_submission_mock_from_file("test1_correct.c")

    submission.expects(:graded_at=)
    submission.expects(:points=).with(135)
    submission.expects(:grader_comment=).with do |value|
      /^PASSED/.match(value)
    end
    submission.expects(:compiler_message=).with('')
    submission.expects(:save)

    # mock task
    task = stub(:id => 1, :submission_id => submission.id)
    Task.expects(:get_inqueue_and_change_status).returns(task)
    task.expects(:status_complete!)

    # mock Submission
    Submission.expects(:find).with(task.submission_id).returns(submission)

    @engine.grade_oldest_task
  end

  def test_grade_oldest_task_with_grader_process
    grader_process = stub
    grader_process.expects(:report_active)

    @engine = Grader::Engine.new(grader_process)

    test_grade_oldest_task
  end

  protected

  def clear_sandbox
    clear_cmd = "rm -rf #{@config.test_sandbox_dir}/*"
    system(clear_cmd)
  end

  def init_sandbox
    clear_sandbox
    Dir.mkdir @config.user_result_dir
    cp_cmd = "cp -R #{@config.test_data_dir}/ev #{@config.test_sandbox_dir}"
    system(cp_cmd)
  end

  def create_submission_from_file(id, user, problem, source_fname, language = @@lang_c)
    source = File.open(@config.test_data_dir + "/" + source_fname).read
    stub(Submission,
         :id => id, :user => user, :problem => problem,
         :source => source, :language => language)
  end

  def create_test1_submission_mock_from_file(source_fname)
    create_submission_from_file(1, @user_user1, @problem_test1, source_fname)
  end
  
end
