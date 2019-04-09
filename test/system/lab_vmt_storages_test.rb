require "application_system_test_case"

class LabVmtStoragesTest < ApplicationSystemTestCase
  setup do
    @lab_vmt_storage = lab_vmt_storages(:one)
  end

  test "visiting the index" do
    visit lab_vmt_storages_url
    assert_selector "h1", text: "Lab Vmt Storages"
  end

  test "creating a Lab vmt storage" do
    visit lab_vmt_storages_url
    click_on "New Lab Vmt Storage"

    fill_in "Controller", with: @lab_vmt_storage.controller
    fill_in "Device", with: @lab_vmt_storage.device
    fill_in "Port", with: @lab_vmt_storage.port
    click_on "Create Lab vmt storage"

    assert_text "Lab vmt storage was successfully created"
    click_on "Back"
  end

  test "updating a Lab vmt storage" do
    visit lab_vmt_storages_url
    click_on "Edit", match: :first

    fill_in "Controller", with: @lab_vmt_storage.controller
    fill_in "Device", with: @lab_vmt_storage.device
    fill_in "Port", with: @lab_vmt_storage.port
    click_on "Update Lab vmt storage"

    assert_text "Lab vmt storage was successfully updated"
    click_on "Back"
  end

  test "destroying a Lab vmt storage" do
    visit lab_vmt_storages_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Lab vmt storage was successfully destroyed"
  end
end
