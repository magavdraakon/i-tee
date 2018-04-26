class LabVmtNetwork < ActiveRecord::Base
	belongs_to :network 
	belongs_to :lab_vmt

	validates_presence_of :slot, :network_id
	validates_uniqueness_of :slot, scope: :lab_vmt_id
	# TODO? validate ip (v4 or v6?)
	validates_uniqueness_of :network_id, scope: [:lab_vmt_id, :slot]

end
