class Vm < ActiveRecord::Base
  has_one :mac
  belongs_to :user
  belongs_to :lab_vmt

end
