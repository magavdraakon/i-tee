class Storage  < ActiveRecord::Base
	has_many :lab_vmt_storages
	validates_presence_of  :storage_type, :path
	validates_uniqueness_of :path, scope: :storage_type

	def available
    available = ["none", "emptydrive"]
   	# read from folder
    available + Dir.entries(Storage.folder)-['.', '..']
  end

  def menustr
    "#{path} (#{storage_type})"
  end

  def location
    if ['none', 'emptydrive'].include?(path)
      path
    else
      "#{Storage.folder}/#{path}"
    end
  end

  def self.folder
    begin
      folder = Rails.configuration.drive_location 
    rescue
      folder = "/var/labs/isos"
    end
    folder = folder.chomp('/') if folder.end_with?('/')
    folder
  end
end
