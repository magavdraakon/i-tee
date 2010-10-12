class EmulateEycalyptus
  def getImages
    return [{:aws_kernel_id=>"eki-F70410FC", :aws_owner=>"admin", :aws_ramdisk_id=>"eri-0B881166", :aws_is_public=>true, :aws_id=>"emi-E0DF1082", :aws_architecture=>"x86_64", :root_device_name=>"/dev/sda1", :root_device_type=>"instance-store", :aws_location=>"image-store-1284546848/image.manifest.xml", :aws_image_type=>"machine", :aws_state=>"available"}, {:aws_owner=>"admin", :aws_is_public=>true, :aws_id=>"eki-F70410FC", :aws_architecture=>"x86_64", :root_device_name=>"/dev/sda1", :root_device_type=>"instance-store", :aws_location=>"image-store-1284546848/kernel.manifest.xml", :aws_image_type=>"kernel", :aws_state=>"available"}, {:aws_owner=>"admin", :aws_is_public=>true, :aws_id=>"eri-0B881166", :aws_architecture=>"x86_64", :root_device_name=>"/dev/sda1", :root_device_type=>"instance-store", :aws_location=>"image-store-1284546848/ramdisk.manifest.xml", :aws_image_type=>"ramdisk", :aws_state=>"available"}]
  end

  def getInstances
    return []
  end

  def terinateInstance(aws_instance_id)
    return true
  end

  def startInstance
    return true
  end

  def getRunningInstances
    return []
  end

  def killall
    return true
  end

end
