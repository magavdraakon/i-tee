require 'test_helper'

class VmTest < ActiveSupport::TestCase
  # Replace this with your real tests.
   test 'second vm existance' do
    assert_not_nil vms(:two)
  end
  
   test 'first vm existance' do
    assert_not_nil vms(:one)
  end
  
  # testing validations:  :name, :lab_vmt_id, :user_id
  test 'vm doesnt save without name labvmt and user' do
    vm=Vm.new
    #without all 3
    assert !vm.save, 'vm doesnt save without name labvmt and user'
    #without 2 of them
    vm.name=nil
    vm.user=users(:ttanav)
    vm.lab_vmt=nil
    assert !vm.save, 'vm doesnt save without name and labvmt'
    vm.name=nil
    vm.user=nil
    vm.lab_vmt=lab_vmts(:one)
    assert !vm.save, 'vm doesnt save without name and user'
    vm.name='name'
    vm.user=nil
    vm.lab_vmt=nil
    assert !vm.save, 'vm doesnt save without user and labvmt'
    #without 1 of them
    vm.name=nil
    vm.user=users(:ttanav)
    vm.lab_vmt=lab_vmts(:one)
    assert !vm.save, 'vm doesnt save without name'
    vm.name='name'
    vm.user=users(:ttanav)
    vm.lab_vmt=nil
    assert !vm.save, 'vm doesnt save without labvmt '
    vm.name='name'
    vm.user=nil
    vm.lab_vmt=lab_vmts(:one)
    assert !vm.save, 'vm doesnt save without user '
  
  end
  
  test 'vm saves with name labvmt and user' do
    vm=Vm.new
    vm.name='name'
    vm.user=users(:ttanav)
    vm.lab_vmt=lab_vmts(:one)
    assert vm.save, 'vm saves with name labvmt and user'
  end
  
  #testing relations: has one :mac belongs to :user :lab_vmt
  test 'first vm has a mac' do
    vm=vms(:one)
    assert vm.mac
    assert_equal vm.mac, macs(:one)
  end
   test 'second vm doesnt have a mac' do
    vm=vms(:two)
    assert !vm.mac
  end
  test 'vms belonging to user and labvmt' do
    vm=vms(:one)
    user=vm.user
    labvmt=vm.lab_vmt
    assert user
    assert_equal user, users(:ttanav)
    assert labvmt
    assert_equal labvmt, lab_vmts(:one)
    
    vm=vms(:two)
    user=vm.user
    labvmt=vm.lab_vmt
    assert user
    assert_equal user, users(:ttanav)
    assert labvmt
    assert_equal labvmt, lab_vmts(:two)
  end
  # testing methods: rel_mac, add_pw(8)
  test 'method rel mac' do
    vm=vms(:one)
    vm.rel_mac
    mac=vm.mac
    r_mac_vm=macs(:one).vm
    assert_nil mac
    assert_nil r_mac_vm
  end
  test 'method add pw' do
     vm=vms(:one)
     assert (vm.password=='generatedone')
    vm.add_pw
    assert !(vm.password=='generatedone')
    assert (vm.password.length==8)
  end
  # testing filters: before destroy rel_mac, before save add_pw
  test 'before save' do
    vm=Vm.new
    vm.name='name'
    vm.user=users(:ttanav)
    vm.lab_vmt=lab_vmts(:one)
    
    assert_nil vm.password
    
    vm.save
    assert (vm.password.length==8)
  end
  test 'before destroy' do
    vm=vms(:one)
    assert vm.mac
    vm.destroy
    mac=macs(:one)
    assert_nil mac.vm
    
  end
  
end
