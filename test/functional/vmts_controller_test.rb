require 'test_helper'

class VmtsControllerTest < ActionController::TestCase
  setup do
    @vmt = vmts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:vmts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create vmt" do
    assert_difference('Vmt.count') do
      post :create, :vmt => @vmt.attributes
    end

    assert_redirected_to vmt_path(assigns(:vmt))
  end

  test "should show vmt" do
    get :show, :id => @vmt.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @vmt.to_param
    assert_response :success
  end

  test "should update vmt" do
    put :update, :id => @vmt.to_param, :vmt => @vmt.attributes
    assert_redirected_to vmt_path(assigns(:vmt))
  end

  test "should destroy vmt" do
    assert_difference('Vmt.count', -1) do
      delete :destroy, :id => @vmt.to_param
    end

    assert_redirected_to vmts_path
  end
end
