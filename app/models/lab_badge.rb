class LabBadge < ActiveRecord::Base
	belongs_to :badge
  	belongs_to :lab

  	has_many :user_badges, :dependent => :destroy
end
