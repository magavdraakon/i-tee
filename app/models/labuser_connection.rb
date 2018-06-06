class LabuserConnection < ActiveRecord::Base
  #attr_accessible :end_at, :labuser_id, :start_at

  belongs_to :lab_user
end
