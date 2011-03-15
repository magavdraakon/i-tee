class Vm < ActiveRecord::Base
  has_one :mac
  belongs_to :user
  belongs_to :lab_vmt
  before_destroy :delete_vms

  def del_vm
    return %x(/var/www/railsapps/i-tee/utils/stop_machine.sh #{name}  2>&1)
  end
  
end
