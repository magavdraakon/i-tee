require 'test_helper'

# todo: add more tests for the existing methods
class LabUsersControllerTest < ActionController::TestCase
  setup do
    sign_in users(:ttanav)
    @lab_user = lab_users(:one)
    #setting a previous page
    request.env["HTTP_REFERER"] = lab_users_path
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:lab_users)
  end

  # method 'new' has been merged with index!
  # test "should get new" do
  #  get :new
  #  assert_response :success
  #  end

  test "should create lab_user" do
    assert_difference('LabUser.count') do
      post :create, :lab_user => @lab_user.attributes
    end

    assert_redirected_to lab_users_path
  end

  #method 'show' is not used
  # test "should show lab_user" do
  #  get :show, :id => @lab_user.to_param
  #  assert_response :success
  # end
  
  test "should get edit" do
    get :edit, :id => @lab_user.to_param
    assert_response :success
  end

  test "should update lab_user" do
    put :update, :id => @lab_user.to_param, :lab_user => @lab_user.attributes
    assert_redirected_to lab_users_path
  end

  test "should destroy lab_user" do
    assert_difference('LabUser.count', -1) do
      delete :destroy, :id => @lab_user.to_param
    end

    assert_redirected_to lab_users_path
  end
end
