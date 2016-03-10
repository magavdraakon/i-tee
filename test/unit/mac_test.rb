require 'test_helper'

class MacTest < ActiveSupport::TestCase
  # Replace this with your real tests.
   test 'second mac existance' do
    assert_not_nil macs(:two)
  end
  
  test 'first mac existance' do
    assert_not_nil macs(:one)
  end
  
  # testing relations
  
  test 'first mac has the first vms' do
    mac=macs(:one)
    vms=mac.vm
    assert vms
    assert_equal vms, vms(:one)
  end
  test 'second mac has no vms' do
    mac=macs(:two)
    vms=mac.vm
    assert_nil vms
  end
  
end
