require 'test_helper'

class LabVmtsControllerTest < ActionController::TestCase
  setup do
    sign_in users(:ttanav)
    @lab_vmt = lab_vmts(:one)
    #setting a previous page
    request.env['HTTP_REFERER'] = lab_vmts_path
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:lab_vmts)
  end

  # method 'new' merged with 'index'
  #test "should get new" do
  #  get :new
  #  assert_response :success
  #end

  test 'should create lab_vmt' do
    assert_difference('LabVmt.count') do
      post :create, :lab_vmt => @lab_vmt.attributes
    end

    assert_redirected_to lab_vmts_path
  end

  # method 'show' not used
  #test "should show lab_vmt" do
  #  get :show, :id => @lab_vmt.to_param
  #  assert_response :success
  #end

  test 'should get edit' do
    get :edit, :id => @lab_vmt.to_param
    assert_response :success
  end

  test 'should update lab_vmt' do
    put :update, :id => @lab_vmt.to_param, :lab_vmt => @lab_vmt.attributes
    assert_redirected_to lab_vmts_path
  end

  test 'should destroy lab_vmt' do
    assert_difference('LabVmt.count', -1) do
      delete :destroy, :id => @lab_vmt.to_param
    end

    assert_redirected_to lab_vmts_path
  end
end
