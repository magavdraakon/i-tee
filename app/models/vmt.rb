class Vmt < ActiveRecord::Base
  has_many :lab_vmts, :dependent => :destroy
end
