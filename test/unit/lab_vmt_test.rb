require 'test_helper'

class LabVmtTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test 'second labvmt existance' do
    assert_not_nil lab_vmts(:two)
  end
  
   test 'first labvmt existance' do
    assert_not_nil lab_vmts(:one)
  end
  
  #testing validations
  
  test 'should not save labvmt without vmt, name and lab' do
    labvmt = LabVmt.new
    #all three missing
    assert !labvmt.save, 'labvmt without a vmt, name and lab didnt save'
    #two missing
    labvmt.vmt_id=nil
    labvmt.lab_id=labs(:ntp).id
    labvmt.name=nil
    assert !labvmt.save, 'labvmt without a vmt and name didnt save'
    labvmt.vmt_id=nil
    labvmt.lab_id=nil
    labvmt.name='name'
    assert !labvmt.save, 'labvmt without a vmt and lab didnt save'
    labvmt.vmt_id=vmts(:one).id
    labvmt.lab_id=nil
    labvmt.name=nil
    assert !labvmt.save, 'labvmt without a lab and name didnt save'
    #one missing
    labvmt.vmt_id=nil
    labvmt.lab_id=labs(:ntp).id
    labvmt.name='name'
    assert !labvmt.save, 'labvmt without a vmt didnt save'
    labvmt.vmt_id=vmts(:one).id
    labvmt.name='name'
    labvmt.lab_id=nil
    assert !labvmt.save, 'labvmt without a lab didnt save'
    labvmt.vmt_id=vmts(:one).id
    labvmt.name=nil
    labvmt.lab_id=labs(:ntp).id
    assert !labvmt.save, 'labvmt without a name didnt save'
    
  end
  
  test 'should save labvmt with lab, name and vmt' do
    labvmt = LabVmt.new
    labvmt.vmt_id=vmts(:one).id
    labvmt.lab_id=labs(:ntp).id
    labvmt.name='name'
    assert labvmt.save, 'labvmt with a vmt, name and lab saved'
  end
  
  test 'name can only be alphanumeric' do
    labvmt = LabVmt.new
    labvmt.vmt_id=vmts(:one).id
    labvmt.lab_id=labs(:ntp).id
    labvmt.name='name is @13SD-><--(_//)'
    assert !labvmt.save, 'labvmt with a non-alphanumeric name doesnt save'
  end
  
  #testing relations
  
  test 'first labvmt has lab ntp vmt one and a vms' do
    labvmt=lab_vmts(:one)
    vmt=labvmt.vmt 
    lab=labvmt.lab
    vms=labvmt.vms
    assert vmt
    assert_equal vmt, vmts(:one) 
    assert lab
    assert_equal lab, labs(:ntp) 
    assert vms
    assert_equal vms, [vms(:one)] 
  end
  
  test 'second labvmt has lab veebiserver vmt two and a vms' do
    labvmt=lab_vmts(:two)
    vmt=labvmt.vmt 
    lab=labvmt.lab
    vms=labvmt.vms
    assert vmt
    assert_equal vmt, vmts(:two) 
    assert lab
    assert_equal lab, labs(:veebiserver) 
    assert vms
    assert_equal vms, [vms(:two)] 
  end
  
  test 'vm dependency' do #TODO the destroy, doesnt delete the vm, (seems to remove the relation tho?)
    #but only when i dont check the same vm before destroy
    labvmt=lab_vmts(:one)
    vms=labvmt.vms.first
    assert vms
    assert_equal vms, vms(:one)
    
    #vm=vms(:one)
   # assert !(vm.lab_vmt==nil)
    labvmt.destroy
    vm=vms(:one)
    assert_nil vm.lab_vmt
    
  end
  
  #testing methods
  
  test 'menu string generation' do
    labvmt=lab_vmts(:two)
    assert_equal labvmt.menustr, "#{labvmt.name} - #{labvmt.lab.name}"
  end
end
