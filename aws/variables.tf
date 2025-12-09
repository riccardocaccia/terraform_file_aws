variable "aws_region" { 
  default = "eu-south-1" 
}

variable "aws_access_key" { 
  description = "AWS access key"  
}

variable "aws_secret_key" { 
  description = "AWS secret key" 
}

variable "public_ssh_key" { 
  description = "Public SSH key" 
}

variable "bastion_ip" { 
  description = "Your admin IP" 
}

variable "galaxy_instance_type" { 
  default = "t3.xlarge" 
}

