require 'test_helper'

class NetworksControllerTest < ActionController::TestCase
  setup do
    @network = networks(:one)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:networks)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create network' do
    assert_difference('Network.count') do
      post :create, network: @network.attributes
    end

    assert_redirected_to network_path(assigns(:network))
  end

  test 'should show network' do
    get :show, id: @network.to_param
    assert_response :success
  end

  test 'should get edit' do
    get :edit, id: @network.to_param
    assert_response :success
  end

  test 'should update network' do
    put :update, id: @network.to_param, network: @network.attributes
    assert_redirected_to network_path(assigns(:network))
  end

  test 'should destroy network' do
    assert_difference('Network.count', -1) do
      delete :destroy, id: @network.to_param
    end

    assert_redirected_to networks_path
  end
end
