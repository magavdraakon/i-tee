class LabVmtStorage < ActiveRecord::Base
	belongs_to :storage 
	belongs_to :lab_vmt

	validates_presence_of :controller, :port, :device, :storage_id
	validates_uniqueness_of :controller, scope: [:port, :device, :lab_vmt_id]
end
