class LabBadge < ActiveRecord::Base
	belongs_to :badge
  	belongs_to :lab

  	has_many :user_badges, :dependent => :destroy

  	validates_presence_of :badge_id, :lab_id, :name
 	validates_uniqueness_of :name, :scope => :lab_id
end
