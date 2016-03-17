require 'test_helper'

class LabVmtNetworksControllerTest < ActionController::TestCase
  setup do
    @lab_vmt_network = lab_vmt_networks(:one)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:lab_vmt_networks)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create lab_vmt_network' do
    assert_difference('LabVmtNetwork.count') do
      post :create, lab_vmt_network: @lab_vmt_network.attributes
    end

    assert_redirected_to lab_vmt_network_path(assigns(:lab_vmt_network))
  end

  test 'should show lab_vmt_network' do
    get :show, id: @lab_vmt_network.to_param
    assert_response :success
  end

  test 'should get edit' do
    get :edit, id: @lab_vmt_network.to_param
    assert_response :success
  end

  test 'should update lab_vmt_network' do
    put :update, id: @lab_vmt_network.to_param, lab_vmt_network: @lab_vmt_network.attributes
    assert_redirected_to lab_vmt_network_path(assigns(:lab_vmt_network))
  end

  test 'should destroy lab_vmt_network' do
    assert_difference('LabVmtNetwork.count', -1) do
      delete :destroy, id: @lab_vmt_network.to_param
    end

    assert_redirected_to lab_vmt_networks_path
  end
end
