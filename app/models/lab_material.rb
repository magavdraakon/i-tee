class LabMaterial < ActiveRecord::Base
  belongs_to :lab
  belongs_to :material
end
