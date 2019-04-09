require 'test_helper'

class LabVmtStoragesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lab_vmt_storage = lab_vmt_storages(:one)
  end

  test "should get index" do
    get lab_vmt_storages_url
    assert_response :success
  end

  test "should get new" do
    get new_lab_vmt_storage_url
    assert_response :success
  end

  test "should create lab_vmt_storage" do
    assert_difference('LabVmtStorage.count') do
      post lab_vmt_storages_url, params: { lab_vmt_storage: { controller: @lab_vmt_storage.controller, device: @lab_vmt_storage.device, port: @lab_vmt_storage.port } }
    end

    assert_redirected_to lab_vmt_storage_url(LabVmtStorage.last)
  end

  test "should show lab_vmt_storage" do
    get lab_vmt_storage_url(@lab_vmt_storage)
    assert_response :success
  end

  test "should get edit" do
    get edit_lab_vmt_storage_url(@lab_vmt_storage)
    assert_response :success
  end

  test "should update lab_vmt_storage" do
    patch lab_vmt_storage_url(@lab_vmt_storage), params: { lab_vmt_storage: { controller: @lab_vmt_storage.controller, device: @lab_vmt_storage.device, port: @lab_vmt_storage.port } }
    assert_redirected_to lab_vmt_storage_url(@lab_vmt_storage)
  end

  test "should destroy lab_vmt_storage" do
    assert_difference('LabVmtStorage.count', -1) do
      delete lab_vmt_storage_url(@lab_vmt_storage)
    end

    assert_redirected_to lab_vmt_storages_url
  end
end
