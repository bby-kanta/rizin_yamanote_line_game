require "test_helper"

class QuizSessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get quiz_sessions_index_url
    assert_response :success
  end

  test "should get show" do
    get quiz_sessions_show_url
    assert_response :success
  end

  test "should get new" do
    get quiz_sessions_new_url
    assert_response :success
  end

  test "should get create" do
    get quiz_sessions_create_url
    assert_response :success
  end

  test "should get join" do
    get quiz_sessions_join_url
    assert_response :success
  end

  test "should get start" do
    get quiz_sessions_start_url
    assert_response :success
  end

  test "should get submit_answer" do
    get quiz_sessions_submit_answer_url
    assert_response :success
  end
end
