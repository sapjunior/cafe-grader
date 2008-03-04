#require 'test/unit'
#require 'rubygems'
#require 'mocha'

require File.join(File.dirname(__FILE__),'spec_helper')

describe "A grader engine, when grading a submission" do

  before(:each) do
    @@lang_c = stub(Language, :name => 'c', :ext => 'c')
    @@lang_cpp = stub(Language, :name => 'cpp', :ext => 'cpp')
    @@lang_pas = stub(Language, :name => 'pas', :ext => 'pas')

    @config = Grader::Configuration.get_instance

    # this test is from Pong
    @problem_test_normal = stub(Problem,
                                :id => 1, :name => 'test_normal', 
                                :full_score => 135)
    @user_user1 = stub(User,
                       :id => 1, :login => 'user1')
    
    @engine = Grader::Engine.new    

    init_sandbox
  end

  it "should grade normal submission" do
    grader_should(:grade => "test1_correct.c",
                  :on => @problem_test_normal,
                  :and_report => {
                    :score => 135,
                    :comment => /^PASSED/})
  end
  

  it "should produce error message when submission cannot compile" do
    grader_should(:grade => "test1_compile_error.c",
                  :on => @problem_test_normal,
                  :and_report => {
                    :score => 0,
                    :comment => 'FAILED: compile error',
                    :compiler_message => /[Ee]rror/})
  end

  it "should produce timeout error when submission runs forever" do
    @problem_test_timeout = stub(Problem,
                                 :id => 1, :name => 'test_timeout', 
                                 :full_score => 10)
    grader_should(:grade => "test2_timeout.c",
                  :on => @problem_test_timeout,
                  :and_report => {
                    :score => 0,
                    :comment => 'FAILED: TT'})
  end

  it "should produce timeout error correctly when submission runs slower than expected in less than a second" do
    @problem_test_timeout = stub(Problem,
                                 :id => 1, :name => 'test_timeout', 
                                 :full_score => 20)
    grader_should(:grade => "test2_1-5sec.c",
                  :on => @problem_test_timeout,
                  :and_report => {
                    :score => 10,
                    :comment => 'FAILED: TP'})
  end
  
  it "should produce runtime error when submission uses too much static memory" do
    @problem_test_memory = stub(Problem,
                                :id => 1, :name => 'test_memory', 
                                :full_score => 20)
    grader_should(:grade => "add_too_much_memory_static.c",
                  :on => @problem_test_memory,
                  :and_report => {
                    :score => 10,
                    :comment => /FAILED: [^P]P/})
  end

  it "should not allow submission to allocate too much dynamic memory" do
    @problem_test_memory = stub(Problem,
                                :id => 1, :name => 'test_memory', 
                                :full_score => 20)
    grader_should(:grade => "add_too_much_memory_dynamic.c",
                  :on => @problem_test_memory,
                  :and_report => {
                    :score => 10,
                    :comment => /FAILED: [^P]P/})
  end

  def grader_should(args)
    @user1 = stub(User,
                  :id => 1, :login => 'user1')
    submission = 
      create_submission_from_file(1, @user1, args[:on], args[:grade])
    submission.should_receive(:graded_at=)

    expected_score = args[:and_report][:score]
    expected_comment = args[:and_report][:comment]
    if args[:and_report][:compiler_message]!=nil
      expected_compiler_message = args[:and_report][:compiler_message]
    else
      expected_compiler_message = ''
    end

    submission.should_receive(:points=).with(expected_score)
    submission.should_receive(:grader_comment=).with(expected_comment)
    submission.should_receive(:compiler_message=).with(expected_compiler_message)
    submission.should_receive(:save)

    @engine.grade(submission)
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
    create_submission_from_file(1, @user_user1, @problem_test_normal, source_fname)
  end
  
end


describe "A grader engine, when working with task queue" do
  before(:each) do
    @@lang_c = stub(Language, :name => 'c', :ext => 'c')
    @@lang_cpp = stub(Language, :name => 'cpp', :ext => 'cpp')
    @@lang_pas = stub(Language, :name => 'pas', :ext => 'pas')

    @config = Grader::Configuration.get_instance
    @problem_test_normal = stub(Problem,
                                :id => 1, :name => 'test_normal', 
                                :full_score => 135)
    @user_user1 = stub(User,
                       :id => 1, :login => 'user1')
    
    @engine = Grader::Engine.new    
    init_sandbox
  end

  it "should just return nil when there is no submission" do
    Task.should_receive(:get_inqueue_and_change_status).and_return(nil)
    @engine.grade_oldest_task.should be_nil
  end

  it "should grade oldest task in queue" do
    submission = create_test1_submission_mock_from_file("test1_correct.c")

    submission.should_receive(:graded_at=)
    submission.should_receive(:points=).with(135)
    submission.should_receive(:grader_comment=).with(/^PASSED/)
    submission.should_receive(:compiler_message=).with('')
    submission.should_receive(:save)

    # mock task
    task = stub(Task,:id => 1, :submission_id => submission.id)
    Task.should_receive(:get_inqueue_and_change_status).and_return(task)
    task.should_receive(:status_complete!)

    # mock Submission
    Submission.should_receive(:find).
      with(task.submission_id).
      and_return(submission)

    @engine.grade_oldest_task
  end

  # to be converted
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
    create_submission_from_file(1, @user_user1, @problem_test_normal, source_fname)
  end
  
end
