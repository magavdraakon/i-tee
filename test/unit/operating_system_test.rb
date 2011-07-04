require 'test_helper'

class OperatingSystemTest < ActiveSupport::TestCase
  # Replace this with your real tests.
   test "second labvmt existance" do
    assert_not_nil operating_systems(:windows)
  end
  
   test "first labvmt existance" do
    assert_not_nil operating_systems(:ubuntu)
  end
  
  # test relations
  test "ubuntu os has vmts" do
    os=operating_systems(:ubuntu)
    vmts=os.vmts
    assert vmts
    assert_equal vmts, [vmts(:two), vmts(:one)]
  end
  
  test "windows os has no vmts" do
    os=operating_systems(:windows)
    vmts=os.vmts
    assert_equal vmts, []
  end
end
