class ImportLabs < ActiveRecord::Base
require 'find' 

@@dir = Rails.configuration.export_location ? Rails.configuration.export_location : '/var/labs/exports'

def self.get_folder
	@@dir
end

# read folders in var/labs/export to list available imports
def self.list_all_labs
	folders = []
	Find.find(@@dir) do |f|  
	  if File.directory?(f) && f!=@@dir
	  	time = ''
	  	name = f.gsub(@@dir, '')
	  	filename = f+'/timestamp.txt'
		if File.exists?(filename) && File.file?(filename)
			file = File.open(filename , 'r') 
			time = file.read.to_datetime
		end
		folders << {folder: name, time: time}
	  end  
	end  
	folders
end

def self.list_importable_labs
	folders = []
	Find.find(@@dir) do |f|  
	  if File.directory?(f) && f!=@@dir
	  	time = ''
	  	name = f.gsub(@@dir, '')
	  	filename = f+'/timestamp.txt'
		if File.exists?(filename) && File.file?(filename)
			file = File.open(filename , 'r') 
			time = file.read.to_datetime
		end
		# find if this lab 
		lab = Lab.where(" REPLACE(name, ' ', '_') = ? ", name.gsub('/','') ).first
		unless lab
			folders << {folder: name, time: time}
		end
	  end  
	end  
	folders
end

def self.get_lab_timestamp(name)
	foldername = name.gsub(' ', '_')
	dirname = @@dir+'/'+foldername
	if File.exists?(dirname) && File.directory?(dirname)
		filename = dirname+'/timestamp.txt'
		if File.exists?(filename) && File.file?(filename)
			file = File.open(filename , 'r') 
			{folder: foldername, time: file.read.to_datetime}
		else
			{folder: foldername, time: ''}
		end
	else
		{folder: '-none-', time: ''}
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
		h_file = dirname+'/host.json'
		l_file = dirname+'/lab.json'
		v_file = dirname+'/lab_vmts.json'
		# read host 
		if File.exists?(h_file) && File.file?(h_file)
			host_file = File.open(h_file , 'r') 
			host_obj = JSON.parse(host_file.read)
			host_obj.delete('id') # remove id field

			host = Host.where("name=?", host_obj['name']).first
			if host
				unless host.update_attributes(host_obj)
					return {success: false, message: "host can not be updated #{host['name']}"}
				end
			else
				host = Host.new(host_obj)
				unless host.save
					return {success: false, message: "host can not be created #{host['name']}"}
				end
			end
			# if no errors, continue
			if File.exists?(l_file) && File.file?(l_file)
				lab_file = File.open(l_file , 'r') 
				lab_obj = JSON.parse(lab_file.read)
				lab_obj['host_id'] = host.id # set new host id
				lab_obj.delete('id') # remove id field
				
				lab = Lab.where("name=?", lab_obj['name']).first # find if this lab already exists (unique name)
				if lab
					unless lab.update_attributes(lab_obj)
						return {success: false, message: "lab can not be updated #{lab_obj['name']}"}
					end
				else
					lab = Lab.new(lab_obj)
					unless lab.save
						return {success: false, message: "lab can not be created #{lab_obj['name']}"}
					end
				end
				# if no errors, continue
				if File.exists?(v_file) && File.file?(v_file)
					vmts_file = File.open(v_file , 'r') 
					vmts_obj = JSON.parse(vmts_file.read)
					
					vmts_obj.each do |lvmt|
						#puts lvmt
						puts "\ndo stuff\n"
						lvmt.delete('id') # remove id from lab_vmt
						lvmt['lab_id'] = lab.id # set new lab id
						# get os
						lvmt['vmt'].delete('id') # remove id from vmt
						lvmt['vmt']['os'].delete('id') # remove  id from os
						os = OperatingSystem.where('name = ? ', lvmt['vmt']['os']['name']).first
						if os
							unless os.update_attributes(lvmt['vmt']['os'])
								return {success: false, message: "OS can not be updated #{lvmt['vmt']['os']['name']}"}
							end
						else
							os = OperatingSystem.new(lvmt['vmt']['os'])
							unless os.save
								return {success: false, message: "os can not be created #{lvmt['vmt']['os']['name']}"}
							end
						end
						lvmt['vmt'].delete('os') # remove os hash
						lvmt['vmt']['operating_system_id'] = os.id # updade os id
						
						# get vmt 
						vmt = Vmt.where('image=?', lvmt['vmt']['image']).first
						if vmt
							unless vmt.update_attributes(lvmt['vmt'])
								return {success: false, message: "vmt can not be updated #{lvmt['vmt']['image']}"}
							end
						else
							vmt = Vmt.new(lvmt['vmt'])
							unless vmt.save
								return {success: false, message: "vmt can not be created #{lvmt['vmt']['image']}"}
							end
						end
						lvmt.delete('vmt') # remove vmt hash
						lvmt['vmt_id'] = vmt.id # set new vmt id
						
						l_nets=lvmt.delete('lab_vmt_networks') # extract networks
						# if no errors try to find the lab_vmt
						lab_vmt = LabVmt.where('name=?', lvmt['name'] ).first
						if lab_vmt
							unless lab_vmt.update_attributes(lvmt)
								return {success: false, message: "lab vmt can not be updated #{lvmt['name']}"}
							end
						else
							lab_vmt = LabVmt.new(lvmt)
							unless lab_vmt.save
								return {success: false, message: "lab vmt can not be created #{lvmt['name']}"}
							end
						end
						# delete all existing lab vmt networks bound to this lab vmt
						LabVmtNetwork.where("lab_vmt_id=?", lab_vmt.id).destroy_all
						#get l_v_n + networks
						l_nets.each do |vnet|
							vnet.delete('id') # remove id from lab_vmt_network
							vnet['network'].delete('id') # remove id from network
							vnet['lab_vmt_id']=lab_vmt.id # set new lab vmt id

							network = Network.where('name=?', vnet['network']['name']).first
							if network
								unless network.update_attributes(vnet['network'])
									return {success: false, message: "network can not be updated #{vnet['network']['name']}"}
								end
							else
								network = Network.new(vnet['network'])
								unless network.save
									return {success: false, message: "network can not be created #{vnet['network']['name']}"}
								end
							end
							vnet['network_id']=network.id 
							vnet.delete('network')
							# create new network card
							puts vnet
							lab_vmt_network = LabVmtNetwork.new(vnet)
							unless lab_vmt_network.save
								return {success: false, message: "lab vmt #{lab_vmt.name} network can not be created #{vnet['slot']}"}
							end
						end
					end
					# if not returned by now, success
					{success: true, message: "lab #{lab.id} imported from #{dirname}"}
				else
					{success: false, message: "vmts file does not exist #{dirname}"}
				end
				
			else
				{success: false, message: "lab file does not exist #{dirname}"}
			end

		else
			{success: false, message: "host file does not exist #{dirname}"}
		end
		
	else
		{success: false, message: "folder does not exist #{dirname}"}
	end
end


def self.export_lab_separate(id)
	# get lab
	l = Lab.where("id=?", id).first
	if l # lab exists
		unless File.exists?(@@dir) && File.directory?(@@dir)
			return {success: false, message: "folder does not exist #{@@dir}"}
		end
		dirname = @@dir+'/'+l.name.gsub(' ', '_')
		# check if folder exists
		unless File.directory?(dirname)
			# make folder
			begin
				Dir.mkdir(dirname) 
				#info = %x(sudo -Hu vbox mkdir #{Shellwords.escape(dirname)} )
				#status = $?
				#unless status.exitstatus===0
			rescue Exception => e
				return {success: false, message: "Unable to create folder #{dirname} - #{e.message}"}
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
		return {success: true, message: "Lab #{lab.name} exported to #{dirname}"}
	else
		return {success: false, message: "Could not find lab with id #{id}"}
	end

end


def self.export_lab(id)
	# get lab
	l = Lab.where("id=?", id).first
	if l # lab exists
		unless File.exists?(@@dir) && File.directory?(@@dir)
			return {success: false, message: "folder does not exist #{@@dir}"}
		end
		dirname = @@dir+'/'+l.name.gsub(' ', '_')
		# check if folder exists
		unless File.directory?(dirname)
			# make folder
			begin
				Dir.mkdir(dirname) 
				#info = %x(sudo -Hu vbox mkdir #{Shellwords.escape(dirname)} )
				#status = $?
				#unless status.exitstatus===0
			rescue Exception => e
				return {success: false, message: "Unable to create folder #{dirname} - #{e.message}"}
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
		return {success: true, message: "Lab #{l.name} exported to #{dirname}"}
	else
		return {success: false, message: "Could not find lab with id #{id}"}
	end

end

end
