class UserBadge < ActiveRecord::Base
	belongs_to :user
  	belongs_to :lab_badge

  	validates_presence_of :user_id, :lab_badge_id
end
