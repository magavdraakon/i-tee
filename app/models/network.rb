class Network < ActiveRecord::Base
	has_many :lab_vmt_networks
	validates_uniqueness_of :name
end
