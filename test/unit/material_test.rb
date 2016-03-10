require 'test_helper'

class MaterialTest < ActiveSupport::TestCase
  # Replace this with your real tests.
   test 'second material existance' do
    assert_not_nil materials(:npt)
  end
  
   test 'first labvmt existance' do
    assert_not_nil materials(:veebiserver)
  end
  
  #testing validations
  
  test 'material doesnt save without name' do
    material=Material.new
    assert !material.save, 'material doesnt save without a name'
  end
  
  test 'material saves with a name' do
    material=Material.new
    material.name='name'
    assert material.save, 'material saves with a name'
  end
  
end
