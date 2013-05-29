class Badge < ActiveRecord::Base
	has_many :lab_badges, :dependent => :destroy

	validates_presence_of :icon, :placeholder
end
