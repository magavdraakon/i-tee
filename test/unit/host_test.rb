require 'test_helper'

class HostTest < ActiveSupport::TestCase
  # TODO: add tests once model has validations etc
  
    test 'first host existance' do
    assert_not_nil hosts(:host1)
  end
  
   test 'second host existance' do
    assert_not_nil hosts(:host2)
  end
  
  test 'get first host ip' do
    assert hosts(:host1).ip='192.168.13.13'
  end
  
  test 'get second host ip' do
    assert hosts(:host2).ip='192.168.13.2'
  end
end
