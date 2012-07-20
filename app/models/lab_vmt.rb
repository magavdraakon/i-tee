class LabVmt < ActiveRecord::Base
  belongs_to :lab
  belongs_to :vmt
  has_many :vms, :dependent => :destroy
  
  validates_presence_of :lab_id, :vmt_id, :name
  validates_format_of :name, :with => /^[[:alnum:]\d-]+$/, :message => "can only be alphanumeric with no spaces"
  
  def menustr
    "#{name} - #{lab.name}"
  end
  
end
