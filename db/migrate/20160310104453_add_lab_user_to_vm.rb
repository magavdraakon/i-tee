class AddLabUserToVm < ActiveRecord::Migration
  def change
    add_column :vms, :lab_user_id, :integer

    # reset class ref
    Vm.reset_column_information
    Vm.all.each do |vm|
    	#find labuser
    	lu = LabUser.where("user_id=? and lab_id=?", vm.user_id, vm.lab_vmt.lab_id).last # always take the last as it is most likely to be active
    	if lu
    		vm.lab_user_id=lu.id
    		#save
    		vm.save
    	end
    end
  end
end
