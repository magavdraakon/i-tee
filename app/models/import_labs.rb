class ImportLabs < ActiveRecord::Base
require 'find' 

@@dir = Rails.configuration.export_location

# read folders in var/labs/export to list available imports
def self.list_labs
	puts "trying to read location: #{Rails.configuration.export_location} "
	Find.find(Rails.configuration.export_location) do |f|  
  type = case  
         when File.file?(f) then "F"  
         when File.directory?(f) then "D"  
         else "?"  
         end  
  puts "#{type}: #{f}"  
end  

end

# read folder contents var/labs/export/labname
# json files for lab_vmts
# json file for lab 
# json file for host
def self.import_from_folder(foldername)
	dirname = @@dir+'/'+foldername
	if !foldername.blank? && File.exists?(dirname)
		puts "folder exists #{dirname}"
		if File.exists?(dirname+'/lab.json') && File.file?(dirname+'/lab.json')
			lab_file = File.open(dirname+'/lab.json' , 'r') 
			lab_obj = JSON.parse(lab_file.read)
			puts lab_obj  
			# TODO: find if this lab already exists (unique name)
		end
	else
		puts "folder does not exist #{dirname}"
	end
end


def self.export_lab_separate(id)
	# get lab
	l = Lab.where("id=?", id).first
	if l # lab exists
		dirname = @@dir+'/'+l.name.gsub(' ', '_')
		# check if folder exists
		unless File.directory?(dirname)
			# make folder
			info = %x(sudo -u vbox mkdir #{dirname} )
			status = $?
			unless status.exitstatus===0
				puts "unable to create folder #{dirname}"
				return false # return false if folder does not exist and can not be created
			end
		end
		# write to file
		#puts JSON.pretty_generate(l.as_json['lab'])
		File.open(dirname+"/lab.json","w") do |f|
		  f.write( JSON.pretty_generate( l.as_json['lab'] ) )
		end
		File.open(dirname+"/host.json","w") do |f|
		  f.write( JSON.pretty_generate( l.host.as_json['host'] ) )
		end
		# find all lab_vmts
		
		lab_vmts = [] # will fill lab_vmts into here
		lab_vmt_networks = []
		networks = [] # will fill networks into here
		vmts = [] # will fill vmts into here
		os = [] # will fill os-s into here
		l.lab_vmts.each do |lvt|
			lab_vmts << lvt.as_json['lab_vmt']
			lvt.lab_vmt_networks.each do |lvt_n|
				lab_vmt_networks << lvt_n.as_json['lab_vmt_network']
				networks << lvt_n.network.as_json['network']
			end

			vmts << JSON.pretty_generate(lvt.vmt.as_json['vmt'])
			os << JSON.pretty_generate(lvt.vmt.operating_system.as_json['operating_system'])
		end
		# puts JSON.pretty_generate(lab_vmts)
		File.open(dirname+"/lab_vmts.json","w") do |f|
			f.write( JSON.pretty_generate( lab_vmts ) )
		end
		File.open(dirname+"/lab_vmt_networks.json","w") do |f|
			f.write( JSON.pretty_generate( lab_vmt_networks.uniq ) )
		end
		File.open(dirname+"/networks.json","w") do |f|
			f.write( JSON.pretty_generate( networks.uniq ) )
		end
		File.open(dirname+"/vmts.json","w") do |f|
			f.write( JSON.pretty_generate( vmts.uniq ) )
		end
		File.open(dirname+"/os.json","w") do |f|
			f.write( JSON.pretty_generate( os.uniq ) )
		end

		File.open(dirname+"/timestamp.txt","w") do |f|
			f.write( Time.now.to_s )
		end
	end

end


def self.export_lab(id)
	# get lab
	l = Lab.where("id=?", id).first
	if l # lab exists
		dirname = @@dir+'/'+l.name.gsub(' ', '_')
		# check if folder exists
		unless File.directory?(dirname)
			# make folder
			info = %x(sudo -u vbox mkdir #{dirname} )
			status = $?
			unless status.exitstatus===0
				puts "unable to create folder #{dirname}"
				return false # return false if folder does not exist and can not be created
			end
		end
		# write to file
		#puts JSON.pretty_generate(l.as_json['lab'])
		File.open(dirname+"/lab.json","w") do |f|
		  f.write( JSON.pretty_generate( l.as_json['lab'] ) )
		end
		File.open(dirname+"/host.json","w") do |f|
		  f.write( JSON.pretty_generate( l.host.as_json['host'] ) )
		end
		# find all lab_vmts
		
		lab_vmts = [] # will fill lab_vmts into here
		l.lab_vmts.each do |lvt|
			temp_vmt = JSON.parse( JSON.generate( lvt.as_json['lab_vmt'] ))
			lab_vmt_networks = []
			lvt.lab_vmt_networks.each do |lvt_n|
				temp = JSON.parse( JSON.generate( lvt_n.as_json['lab_vmt_network'] ))
				temp['network'] = lvt_n.network.as_json['network']
				
				lab_vmt_networks<<temp
			end
			temp_vmt['lab_vmt_networks'] = lab_vmt_networks
			vmt = lvt.vmt.as_json['vmt']
			os = lvt.vmt.operating_system.as_json['operating_system']
			vmt['os'] = os
			temp_vmt['vmt'] = vmt
			lab_vmts << temp_vmt
		end
		# puts JSON.pretty_generate(lab_vmts)
		File.open(dirname+"/lab_vmts.json","w") do |f|
			f.write( JSON.pretty_generate( lab_vmts ) )
		end
		File.open(dirname+"/timestamp.txt","w") do |f|
			f.write( Time.now.to_s )
		end
		
	end

end

end