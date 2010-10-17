class Eycalyptus
  @@EC2_URL = ITee::Application.config.ec2_url
  @@ACCESS_KEY = ITee::Application.config.access_key
  @@SECRET_KEY = ITee::Application.config.secret_key

  def getImages
    @ec2 = RightAws::Ec2.new(@@ACCESS_KEY, @@SECRET_KEY, :endpoint_url => @@EC2_URL)
      for i in @ec2.describe_images()
      i[:aws_id] if i[:aws_image_type] == "machine"
      end
  end

  def getMachineImages
    @ec2 = RightAws::Ec2.new(@@ACCESS_KEY, @@SECRET_KEY, :endpoint_url => @@EC2_URL)
    #@ec2.describe_images(:aws_image_type => 'machine')
    j = 0
    @machines = []
    for i in @ec2.describe_images()
      if i[:aws_image_type] == "machine"
        @machines[j] = i
      end
      j = j + 1
    end
    return @machines
  end

  def getInstances
    @ec2 = RightAws::Ec2.new(@@ACCESS_KEY, @@SECRET_KEY, :endpoint_url => @@EC2_URL)
    @ec2.describe_instances
  end

  def terinateInstance(aws_instance_id)
    @ec2 = RightAws::Ec2.new(@@ACCESS_KEY, @@SECRET_KEY, :endpoint_url => @@EC2_URL)
    @ec2.terminate_instances(aws_instance_id)
  end

  def startInstance(aws_image_id, user)
    @ec2 = RightAws::Ec2.new(@@ACCESS_KEY, @@SECRET_KEY, :endpoint_url => @@EC2_URL)
    
    if !@ec2.describe_key_pairs(user.username) then      
      @ec2.create_key_pair(user.username)
    end

    @instance = @ec2.run_instances(aws_image_id, 1, 1, ['default'], user.username, 'SomeImportantUserData', 'public')
  end

  def getRunningInstances
    e=[]
    @ec2 = RightAws::Ec2.new(@@ACCESS_KEY, @@SECRET_KEY, :endpoint_url => @@EC2_URL)
    for j in @ec2.describe_instances()
      if j[:aws_owner]=="elab" and j[:aws_state]=="running"
        e << j
      end
    end
     return e
  end

  def killall
    @ec2 = RightAws::Ec2.new(@@ACCESS_KEY, @@SECRET_KEY, :endpoint_url => @@EC2_URL)
    for j in @ec2.describe_instances()
      if j[:aws_owner]=="elab" and j[:aws_state]=="running"
        @ec2.terminate_instances(j[:aws_instance_id])
      end
    end
  end
end
