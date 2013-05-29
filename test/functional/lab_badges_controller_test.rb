require 'test_helper'

class LabBadgesControllerTest < ActionController::TestCase
  setup do
    @lab_badge = lab_badges(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:lab_badges)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create lab_badge" do
    assert_difference('LabBadge.count') do
      post :create, :lab_badge => @lab_badge.attributes
    end

    assert_redirected_to lab_badge_path(assigns(:lab_badge))
  end

  test "should show lab_badge" do
    get :show, :id => @lab_badge.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @lab_badge.to_param
    assert_response :success
  end

  test "should update lab_badge" do
    put :update, :id => @lab_badge.to_param, :lab_badge => @lab_badge.attributes
    assert_redirected_to lab_badge_path(assigns(:lab_badge))
  end

  test "should destroy lab_badge" do
    assert_difference('LabBadge.count', -1) do
      delete :destroy, :id => @lab_badge.to_param
    end

    assert_redirected_to lab_badges_path
  end
end
