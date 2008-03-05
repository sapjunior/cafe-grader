require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__),'engine_spec_helper')

describe "A grader engine" do

  include GraderEngineHelperMethods

  before(:each) do
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

  def create_normal_submission_mock_from_file(source_fname)
    create_submission_from_file(1, @user_user1, @problem_test_normal, source_fname)
  end
  
end

