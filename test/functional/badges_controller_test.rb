require 'test_helper'

class BadgesControllerTest < ActionController::TestCase
  setup do
    @badge = badges(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:badges)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create badge" do
    assert_difference('Badge.count') do
      post :create, :badge => @badge.attributes
    end

    assert_redirected_to badge_path(assigns(:badge))
  end

  test "should show badge" do
    get :show, :id => @badge.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @badge.to_param
    assert_response :success
  end

  test "should update badge" do
    put :update, :id => @badge.to_param, :badge => @badge.attributes
    assert_redirected_to badge_path(assigns(:badge))
  end

  test "should destroy badge" do
    assert_difference('Badge.count', -1) do
      delete :destroy, :id => @badge.to_param
    end

    assert_redirected_to badges_path
  end
end
