class Material < ActiveRecord::Base
   has_many :lab_materials, :dependent => :destroy
  validates_presence_of :name
end
