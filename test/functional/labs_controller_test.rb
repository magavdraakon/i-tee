require 'test_helper'

class LabsControllerTest < ActionController::TestCase
  setup do
    sign_in users(:ttanav)
    @lab = labs(:ntp)
    #setting a previous page
    request.env['HTTP_REFERER'] = labs_path
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:labs)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create lab' do
    assert_difference('Lab.count') do
      post :create, :lab => @lab.attributes
    end

    assert_redirected_to lab_path(assigns(:lab))
  end

  test 'should show lab' do
    get :show, :id => @lab.to_param
    assert_response :success
  end

  test 'should get edit' do
    get :edit, :id => @lab.to_param
    assert_response :success
  end

  test 'should update lab' do
    put :update, :id => @lab.to_param, :lab => @lab.attributes
    assert_redirected_to lab_path(assigns(:lab))
  end

  test 'should destroy lab' do
    assert_difference('Lab.count', -1) do
      delete :destroy, :id => @lab.to_param
    end

    assert_redirected_to labs_path
  end
end
