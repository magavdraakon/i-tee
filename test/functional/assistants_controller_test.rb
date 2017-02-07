require 'test_helper'

class AssistantsControllerTest < ActionController::TestCase
  setup do
    @assistant = assistants(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:assistants)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create assistant" do
    assert_difference('Assistant.count') do
      post :create, assistant: { enabled: @assistant.enabled, uri: @assistant.uri }
    end

    assert_redirected_to assistant_path(assigns(:assistant))
  end

  test "should show assistant" do
    get :show, id: @assistant
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @assistant
    assert_response :success
  end

  test "should update assistant" do
    put :update, id: @assistant, assistant: { enabled: @assistant.enabled, uri: @assistant.uri }
    assert_redirected_to assistant_path(assigns(:assistant))
  end

  test "should destroy assistant" do
    assert_difference('Assistant.count', -1) do
      delete :destroy, id: @assistant
    end

    assert_redirected_to assistants_path
  end
end
