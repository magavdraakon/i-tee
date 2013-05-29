class Badge < ActiveRecord::Base
	has_many :lab_badges, :dependent => :destroy
end
