class EmulateEycalyptus
  def getImages
    return [{:aws_kernel_id=>"eki-F70410FC", :aws_owner=>"admin", :aws_ramdisk_id=>"eri-0B881166", :aws_is_public=>true, :aws_id=>"emi-E0DF1082", :aws_architecture=>"x86_64", :root_device_name=>"/dev/sda1", :root_device_type=>"instance-store", :aws_location=>"image-store-1284546848/image.manifest.xml", :aws_image_type=>"machine", :aws_state=>"available"}, {:aws_owner=>"admin", :aws_is_public=>true, :aws_id=>"eki-F70410FC", :aws_architecture=>"x86_64", :root_device_name=>"/dev/sda1", :root_device_type=>"instance-store", :aws_location=>"image-store-1284546848/kernel.manifest.xml", :aws_image_type=>"kernel", :aws_state=>"available"}, {:aws_owner=>"admin", :aws_is_public=>true, :aws_id=>"eri-0B881166", :aws_architecture=>"x86_64", :root_device_name=>"/dev/sda1", :root_device_type=>"instance-store", :aws_location=>"image-store-1284546848/ramdisk.manifest.xml", :aws_image_type=>"ramdisk", :aws_state=>"available"}]
  end
  
  def getMachineImages
    return [{:aws_id=>"emi-E0DF1082", :aws_architecture=>"x86_64", :root_device_name=>"/dev/sda1", :root_device_type=>"instance-store", :aws_location=>"image-store-1284546848/image.manifest.xml", :aws_image_type=>"machine", :aws_state=>"available", :aws_kernel_id=>"eki-F70410FC", :aws_owner=>"admin", :aws_ramdisk_id=>"eri-0B881166", :aws_is_public=>true}]
  end

  def getInstances
    return [{:ami_launch_index=>"0", :aws_availability_zone=>"cluster1", :aws_product_codes=>[], :ssh_key_name=>"", :aws_instance_id=>"i-447809B4", :aws_reason=>"User requested shutdown.", :aws_reservation_id=>"r-5140098A", :aws_state_code=>48, :aws_image_id=>"emi-E0DF1082", :aws_state=>"terminated", :aws_kernel_id=>"eki-F70410FC", :dns_name=>"192.168.13.101", :aws_groups=>["default"], :aws_owner=>"elab", :monitoring_state=>"false", :aws_instance_type=>"m1.small", :aws_ramdisk_id=>"eri-0B881166", :private_dns_name=>"172.19.1.3", :aws_launch_time=>"2010-10-12T11:45:50.763Z"}, {:ami_launch_index=>"0", :aws_availability_zone=>"cluster1", :aws_product_codes=>[], :ssh_key_name=>"", :aws_instance_id=>"i-4E650A28", :aws_reason=>"", :aws_reservation_id=>"r-53430954", :aws_state_code=>16, :aws_image_id=>"emi-E0DF1082", :aws_state=>"running", :aws_kernel_id=>"eki-F70410FC", :dns_name=>"192.168.13.100", :aws_groups=>["default"], :aws_owner=>"elab", :monitoring_state=>"false", :aws_instance_type=>"m1.small", :aws_ramdisk_id=>"eri-0B881166", :private_dns_name=>"172.19.1.2", :aws_launch_time=>"2010-10-12T11:42:08.25Z"}]
  end

  def terinateInstance(aws_instance_id)
    return true
  end

  def startInstance(aws_instance_id)
    return true
  end

  def getRunningInstances
    return [{:ami_launch_index=>"0", :aws_availability_zone=>"cluster1", :aws_product_codes=>[], :ssh_key_name=>"", :aws_instance_id=>"i-4E650A28", :aws_reason=>"", :aws_reservation_id=>"r-53430954", :aws_state_code=>16, :aws_image_id=>"emi-E0DF1082", :aws_state=>"running", :aws_kernel_id=>"eki-F70410FC", :dns_name=>"192.168.13.100", :aws_groups=>["default"], :aws_owner=>"elab", :monitoring_state=>"false", :aws_instance_type=>"m1.small", :aws_ramdisk_id=>"eri-0B881166", :private_dns_name=>"172.19.1.2", :aws_launch_time=>"2010-10-12T11:42:08.25Z"}]
  end

  def killall
    return true
  end

end
