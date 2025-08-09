require "test_helper"

class GameSessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get game_sessions_index_url
    assert_response :success
  end

  test "should get show" do
    get game_sessions_show_url
    assert_response :success
  end

  test "should get new" do
    get game_sessions_new_url
    assert_response :success
  end

  test "should get create" do
    get game_sessions_create_url
    assert_response :success
  end

  test "should get edit" do
    get game_sessions_edit_url
    assert_response :success
  end

  test "should get update" do
    get game_sessions_update_url
    assert_response :success
  end

  test "should get join" do
    get game_sessions_join_url
    assert_response :success
  end

  test "should get leave" do
    get game_sessions_leave_url
    assert_response :success
  end

  test "should get start_game" do
    get game_sessions_start_game_url
    assert_response :success
  end

  test "should get eliminate_player" do
    get game_sessions_eliminate_player_url
    assert_response :success
  end

  test "should get submit_fighter" do
    get game_sessions_submit_fighter_url
    assert_response :success
  end
end
