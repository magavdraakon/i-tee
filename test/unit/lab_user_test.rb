require 'test_helper'

class LabUserTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "second lab existance" do
    assert_not_nil lab_users(:two)
  end
  
   test "first lab existance" do
    assert_not_nil lab_users(:one)
  end
  
  #testing validations
  
  test "should not save labuser without user and lab" do
    labuser = LabUser.new
    assert !labuser.save, "labuser without a user and lab didnt save"
    labuser.lab_id=labs(:ntp).id
    assert !labuser.save, "labuser without a user didnt save"
    labuser.user_id=users(:ttanav).id
    labuser.lab_id=nil
    assert !labuser.save, "labuser without a lab didnt save"
    
  end
  
  test "should save labuser with lab and user" do
    labuser = LabUser.new
    labuser.lab_id=labs(:ntp).id
     labuser.user_id=users(:ttanav).id
    assert labuser.save, "labuser with a user and lab saved"
  end
  
  #testing relations
  
  test "first labuser has user ttanav and lab ntp" do
   labuser=lab_users(:one)
    user=labuser.user 
    lab=labuser.lab
    assert user
    assert_equal user, users(:ttanav) 
    assert lab
    assert_equal lab, labs(:ntp) 
  end
  
  test "second labuser user ttanav and lab veebiserver" do
    labuser=lab_users(:two)
    user=labuser.user 
    lab=labuser.lab
    assert user
    assert_equal user, users(:ttanav) 
    assert lab
    assert_equal lab, labs(:veebiserver) 
  end  
  
  
end
