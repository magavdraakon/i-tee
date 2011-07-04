require 'test_helper'

class VmtTest < ActiveSupport::TestCase
  # Replace this with your real tests.
   test "second vmt existance" do
    assert_not_nil vmts(:two)
  end
  
   test "first vmt existance" do
    assert_not_nil vmts(:one)
  end
  
  #testing validations :image, :username, :operating_system_id
  test "vmt shouldnt save without image username and os" do
    vmt=Vmt.new
    #without all 3
    assert !vmt.save, "vmt doesnt save without image username and os"
    
    #without 2 of them
    vmt.username=nil
    vmt.image=nil
    vmt.operating_system=operating_systems(:ubuntu)
    assert !vmt.save, "vmt doesnt save without username and image "
    vmt.username=nil
    vmt.image="image"
    vmt.operating_system=nil
    assert !vmt.save, "vmt doesnt save without username and os "
    vmt.username="name"
    vmt.image=nil
    vmt.operating_system=nil
    assert !vmt.save, "vmt doesnt save without image and os "
    
    #without 1 of them
    vmt.username=nil
    vmt.image="image"
    vmt.operating_system=operating_systems(:ubuntu)
    assert !vmt.save, "vmt doesnt save without username "
    vmt.username="name"
    vmt.image=nil
    vmt.operating_system=operating_systems(:ubuntu)
    assert !vmt.save, "vmt doesnt save without image "
    vmt.username="name"
    vmt.image="image"
    vmt.operating_system=nil
    assert !vmt.save, "vmt doesnt save without os "
  end
  test "vmt saves with image username and os" do
    vmt=Vmt.new
    vmt.username="name"
    vmt.image="image"
    vmt.operating_system=operating_systems(:ubuntu)
    assert vmt.save, "vmt saves with image username and os"
  end
  
  #testing relations has many :lab_vmts,:d=>:d, belongs_to :operating_system
  test "has many labvmts dependency" do
    vmt=vmts(:one)
    lvmt=lab_vmts(:one)
    lab_vmt=vmt.lab_vmts.first
    assert lab_vmt
    assert_equal lab_vmt, lvmt
    
    vmt.destroy
    
    lvmt=lab_vmts(:one)
    assert_nil lvmt.vmt
  end
  
  test "belongs to os" do
    vmt=vmts(:one)
    os=operating_systems(:ubuntu)
    vmt_os=vmt.operating_system
    assert vmt_os
    assert_equal vmt_os, os
  end
  
end
