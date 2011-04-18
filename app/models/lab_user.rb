class LabUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :lab
  
  validates_presence_of :user_id, :lab_id
end
