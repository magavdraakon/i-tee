require 'test_helper'

class LabUsersControllerTest < ActionController::TestCase
  setup do
    @lab_user = lab_users(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:lab_users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create lab_user" do
    assert_difference('LabUser.count') do
      post :create, :lab_user => @lab_user.attributes
    end

    assert_redirected_to lab_user_path(assigns(:lab_user))
  end

  test "should show lab_user" do
    get :show, :id => @lab_user.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @lab_user.to_param
    assert_response :success
  end

  test "should update lab_user" do
    put :update, :id => @lab_user.to_param, :lab_user => @lab_user.attributes
    assert_redirected_to lab_user_path(assigns(:lab_user))
  end

  test "should destroy lab_user" do
    assert_difference('LabUser.count', -1) do
      delete :destroy, :id => @lab_user.to_param
    end

    assert_redirected_to lab_users_path
  end
end
