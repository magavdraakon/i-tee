class LabVmtNetwork < ActiveRecord::Base
	belongs_to :network 
	belongs_to :lab_vmt

	validates_uniqueness_of :network_id, scope: [:lab_vmt_id, :slot]
end
