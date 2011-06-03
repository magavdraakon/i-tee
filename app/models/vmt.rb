class Vmt < ActiveRecord::Base
  has_many :lab_vmts, :dependent => :destroy
  belongs_to :operating_system
  validates_presence_of :image, :username, :operating_system_id
end
