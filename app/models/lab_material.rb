class LabMaterial < ActiveRecord::Base
  belongs_to :lab
  belongs_to :material
  
  validates_presence_of :lab_id, :material_id
end
