class Vmt < ActiveRecord::Base
  has_many :lab_vmts, :dependent => :destroy
  validates_presence_of :image
end
