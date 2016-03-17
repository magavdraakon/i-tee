require 'test_helper'

class LabTest < ActiveSupport::TestCase
  # Replace this with your real tests. ruby -Itest test/unit/lab_test.rb
  test 'second lab existance' do
    assert_not_nil labs(:ntp)
  end
  
   test 'first lab existance' do
    assert_not_nil labs(:veebiserver)
  end
  
  #testing validations
  
  test 'should not save lab without title' do
    lab = Lab.new
    assert !lab.save, 'lab without a name didnt save'
  end
  
  test 'should save lab with title' do
    lab = Lab.new
    lab.name='new lab'
    assert lab.save, 'lab with a name saved'
  end
  
  #testing relations
  
  test 'user ttanav has ntp lab' do
    lab=labs(:ntp)
    lab_user=lab.lab_users
    assert lab_user
    assert_equal lab_user, [lab_users(:one)]
  end
  
  test 'user ttanav has veebiserver lab' do
     lab=labs(:veebiserver)
    lab_user=lab.lab_users
    assert lab_user
    assert_equal lab_user, [lab_users(:two)] 
  end  
  
  test 'ntp lab has a vmt' do
     lab=labs(:ntp)
    lab_vmt=lab.lab_vmts
    assert lab_vmt
    assert_equal lab_vmt, [lab_vmts(:one)]
    
  end
  
  test 'veebiserver lab has a vmt' do
    lab=labs(:veebiserver)
    lab_vmt=lab.lab_vmts
    assert lab_vmt
    assert_equal lab_vmt, [lab_vmts(:two)]
  end
  
  test 'user and labvmt dependency' do
    lab=labs(:ntp)
    l_user=lab.lab_users.first
    l_lvmt=lab.lab_vmts.first #take only first to check //there is only one atm anyway
    assert l_user
    assert_equal l_user, lab_users(:one)
    assert l_lvmt
    assert_equal l_lvmt, lab_vmts(:one)
    lab.destroy
    labuser=lab_users(:one)
    labvmt=lab_vmts(:one)
    assert_nil labuser.lab#this goes trough, but when checking only labuser for nil, 
    #it shows that the lab id is still set. i wonder why
    assert_nil labvmt.lab#same
    
  end
  
end
