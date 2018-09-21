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
def self.import_from_folder(foldername)
	dirname = @@dir+'/'+foldername
	if !foldername.blank? && File.exists?(dirname)
		puts "folder exists #{dirname}"
		a_file = dirname+'/assistant.json'
		l_file = dirname+'/lab.json'
		v_file = dirname+'/lab_vmts.json'
		if File.exists?(a_file) && File.file?(a_file)
			assistant_file = File.open(a_file , 'r')
			assistant_obj = JSON.parse(assistant_file.read)
			assistant_obj.delete('id') # remove id field
			if assistant_obj.blank? # no assistant
				assistant = {id: nil}
			else
				assistant = Assistant.where("uri=?", assistant_obj['uri']).first
				# filter out fields not in model
				diff = assistant_obj.keys - Assistant.column_names
				diff.each { |k| assistant_obj.delete k }
				if assistant
					unless assistant.update_attributes(assistant_obj)
						return {success: false, message: "assistant can not be updated #{assistant['uri']}"}
					end
				else
					assistant = Assistant.new(assistant_obj)
					unless assistant.save
						return {success: false, message: "assistant can not be created #{assistant['uri']}"}
					end
				end
			end
		else # no assistant exported
			assistant = {id: nil}
		end
		# if no errors, continue
		if File.exists?(l_file) && File.file?(l_file)
			lab_file = File.open(l_file , 'r')
			lab_obj = JSON.parse(lab_file.read)
			lab_obj['assistant_id'] = assistant[:id] # set new assistant id
			lab_obj.delete('id') # remove id field

			lab = Lab.where("name=?", lab_obj['name']).first # find if this lab already exists (unique name)
			# filter out fields not in model
			diff = lab_obj.keys - Lab.column_names
			diff.each { |k| lab_obj.delete k }
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
				names = []
				vmts_obj.each do |lvmt|
					names << lvmt['name']
					lvmt.delete('id') # remove id from lab_vmt
					lvmt['lab_id'] = lab.id # set new lab id
					lvmt['vmt'].delete('id') # remove id from vmt

					vmt = Vmt.where('image=?', lvmt['vmt']['image']).first
					# filter out fields not in model
					diff = lvmt['vmt'].keys - Vmt.column_names
					diff.each { |k| lvmt['vmt'].delete k }
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

					l_nets = lvmt.delete('lab_vmt_networks') # extract networks
					# if no errors try to find the lab_vmt
					lab_vmt = LabVmt.where('name=?', lvmt['name'] ).first
					# filter out fields not in model
					diff = lvmt.keys - LabVmt.column_names
					diff.each { |k| lvmt.delete k }
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
						# filter out fields not in model
						diff = vnet['network'].keys - Network.column_names
						diff.each { |k| vnet['network'].delete k }
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
						vnet['network_id'] = network.id
						vnet.delete('network')
						# create new network card
						puts vnet
						# filter out fields not in model
						diff = vnet.keys - LabVmtNetwork.column_names
						diff.each { |k| vnet.delete k }
						lab_vmt_network = LabVmtNetwork.new(vnet)
						unless lab_vmt_network.save
							return {success: false, message: "lab vmt #{lab_vmt.name} network can not be created #{vnet['slot']}"}
						end
					end # eof create networking
				end # eof vmts
				# check for vmts with names not included in vmts_obj
				gotnames = lab.lab_vmts.pluck(:name)
				logger.debug "machines: should be #{names} vs found #{gotnames}"
				diff = gotnames - names
				# remove lab_vmts and their networks
				diff.each do |n|
					lab_vmt = LabVmt.where('name=?', n ).first
					LabVmtNetwork.where("lab_vmt_id=?", lab_vmt.id).destroy_all
					LabVmt.where('name=?', n ).destroy_all
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
		#puts JSON.pretty_generate(l.as_json)
		File.open(dirname+"/lab.json","w") do |f|
		  f.write( JSON.pretty_generate( l.as_json ) )
		end
		# find all lab_vmts
		
		lab_vmts = [] # will fill lab_vmts into here
		lab_vmt_networks = []
		networks = [] # will fill networks into here
		vmts = [] # will fill vmts into here
		l.lab_vmts.each do |lvt|
			lab_vmts << lvt.as_json
			lvt.lab_vmt_networks.each do |lvt_n|
				lab_vmt_networks << lvt_n.as_json
				networks << lvt_n.network.as_json
			end

			vmts << JSON.pretty_generate(lvt.vmt.as_json)
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

		File.open(dirname+"/timestamp.txt","w") do |f|
			f.write( Time.now.to_s )
		end
		return {success: true, message: "Lab #{lab.name} exported to #{dirname}"}
	else
		return {success: false, message: "Could not find lab with id #{id}"}
	end

end


def self.export_labuser(uuid, pretty)
	lu = LabUser.where("uuid=?", uuid).first
	if lu
		loginfo = lu.log_info
		logger.info "GETTING LABUSER INFO INFO CALLED: #{loginfo}"
		if lu.start && !lu.end

			lab = lu.lab
			lab = {} unless lab
			
			user = lu.user
			user = {} unless user
			#logger.debug "USER: #{user.as_json.slice('id', 'username', 'name', 'user_key') }"
			assistant = lab.assistant if lab # if lab is blank then there is no assistant
			assistant = {} unless assistant
			#logger.debug "ASSISTANT: #{assistant.as_json.except('created_at', 'updated_at') }"
			conf = JSON.parse( ( lab.config.blank? ? '{}' : lab.config ) )  # extract config JSON string to hash
			#logger.debug conf
			lab = JSON.parse(lab.to_json) # convert lab to hash
			lab[:config] = conf # overwrite conf with hash version
			#logger.debug "LAB: #{lab.as_json.except('created_at', 'updated_at', 'description', 'short_description')}"

			data = {
				success: true,
				lab: lab.as_json.except('created_at', 'updated_at', 'description', 'short_description'),
				assistant: assistant.as_json.except('created_at', 'updated_at'),
				labuser: lu.as_json.except('created_at', 'updated_at'),
				user: user.as_json.slice('id', 'username', 'name', 'user_key'),
				vms: lu.vms.map { |vm|
					r = vm.as_json.except('created_at', 'updated_at', 'description')
					r['lab_vmt'] = vm.lab_vmt.as_json.except('created_at', 'updated_at')
					r['lab_vmt']['lab_vmt_networks'] = vm.lab_vmt.lab_vmt_networks.map{ |n|
						t = n.as_json.except('created_at', 'updated_at')
						t['network'] = n.network.as_json.except('created_at', 'updated_at')
						t
					}
					r['lab_vmt']['vmt'] = vm.lab_vmt.vmt.as_json.except('created_at', 'updated_at')
					r
				}
			}
			logger.info "GETTING LABUSER INFO SUCCESS: #{loginfo}"
			if pretty
				JSON.pretty_generate(data)
			else
				data
			end
		else
			logger.error "GETTING LABUSER INFO INFO FAILED: attempt inactive uuid=#{uuid} #{loginfo}"
			return {success: false, message: "Unable to find active labuser with given uid"}
		end
	else
		logger.error "GETTING LABUSER INFO INFO FAILED: no such labuser uuid=#{uuid}"
		return {success: false, message: "Unable to find labuser with given uid"}
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
		#puts JSON.pretty_generate(l.as_json)
		File.open(dirname+"/lab.json","w") do |f|
		  f.write( JSON.pretty_generate( l.as_json ) )
		end
		File.open(dirname+"/assistant.json","w") do |f|
		  f.write( JSON.pretty_generate( l.assistant ? l.assistant.as_json : {} ) )
		end
		# find all lab_vmts
		
		lab_vmts = [] # will fill lab_vmts into here
		l.lab_vmts.each do |lvt|
			temp_vmt = JSON.parse( JSON.generate( lvt.as_json ))
			lab_vmt_networks = []
			lvt.lab_vmt_networks.each do |lvt_n|
				temp = JSON.parse( JSON.generate( lvt_n.as_json ))
				temp['network'] = lvt_n.network.as_json
				
				lab_vmt_networks<<temp
			end
			temp_vmt['lab_vmt_networks'] = lab_vmt_networks
			vmt = lvt.vmt.as_json
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
