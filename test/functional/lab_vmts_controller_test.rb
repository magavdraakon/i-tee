require 'test_helper'

class LabVmtsControllerTest < ActionController::TestCase
  setup do
    @lab_vmt = lab_vmts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:lab_vmts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create lab_vmt" do
    assert_difference('LabVmt.count') do
      post :create, :lab_vmt => @lab_vmt.attributes
    end

    assert_redirected_to lab_vmt_path(assigns(:lab_vmt))
  end

  test "should show lab_vmt" do
    get :show, :id => @lab_vmt.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @lab_vmt.to_param
    assert_response :success
  end

  test "should update lab_vmt" do
    put :update, :id => @lab_vmt.to_param, :lab_vmt => @lab_vmt.attributes
    assert_redirected_to lab_vmt_path(assigns(:lab_vmt))
  end

  test "should destroy lab_vmt" do
    assert_difference('LabVmt.count', -1) do
      delete :destroy, :id => @lab_vmt.to_param
    end

    assert_redirected_to lab_vmts_path
  end
end
