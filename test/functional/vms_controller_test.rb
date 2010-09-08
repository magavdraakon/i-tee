require 'test_helper'

class VmsControllerTest < ActionController::TestCase
  setup do
    @vm = vms(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:vms)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create vm" do
    assert_difference('Vm.count') do
      post :create, :vm => @vm.attributes
    end

    assert_redirected_to vm_path(assigns(:vm))
  end

  test "should show vm" do
    get :show, :id => @vm.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @vm.to_param
    assert_response :success
  end

  test "should update vm" do
    put :update, :id => @vm.to_param, :vm => @vm.attributes
    assert_redirected_to vm_path(assigns(:vm))
  end

  test "should destroy vm" do
    assert_difference('Vm.count', -1) do
      delete :destroy, :id => @vm.to_param
    end

    assert_redirected_to vms_path
  end
end
