class UserBadge < ActiveRecord::Base
	belongs_to :user
  	belongs_to :lab_badge
end
