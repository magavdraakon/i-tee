require 'test_helper'

class LabMaterialsControllerTest < ActionController::TestCase
  setup do
    @lab_material = lab_materials(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:lab_materials)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create lab_material" do
    assert_difference('LabMaterial.count') do
      post :create, :lab_material => @lab_material.attributes
    end

    assert_redirected_to lab_material_path(assigns(:lab_material))
  end

  test "should show lab_material" do
    get :show, :id => @lab_material.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @lab_material.to_param
    assert_response :success
  end

  test "should update lab_material" do
    put :update, :id => @lab_material.to_param, :lab_material => @lab_material.attributes
    assert_redirected_to lab_material_path(assigns(:lab_material))
  end

  test "should destroy lab_material" do
    assert_difference('LabMaterial.count', -1) do
      delete :destroy, :id => @lab_material.to_param
    end

    assert_redirected_to lab_materials_path
  end
end
