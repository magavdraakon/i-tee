class Material < ActiveRecord::Base
   has_many :lab_materials, :dependent => :destroy
end
