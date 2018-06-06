class LabVmt < ActiveRecord::Base
  belongs_to :lab
  belongs_to :vmt
  has_many :lab_vmt_networks, :dependent => :destroy
  has_many :vms, :dependent => :destroy
  accepts_nested_attributes_for :lab_vmt_networks,:reject_if => proc { |attributes| attributes['slot'].blank? && attributes['network_id'].blank? }, :allow_destroy => true
  
  validates_presence_of  :vmt_id, :name, :nickname
  validates_format_of :name, :with => /\A[[:alnum:]\d-]+\z/, :message => 'can only be alphanumeric with no spaces'
  validates_uniqueness_of :name

  def menustr
    "#{name} (#{lab.name})"
  end

end
