variable "aws_region" { 
  default = "eu-south-1" 
}

variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "public_ssh_key" {
  description = "public ssh key"
}

variable "bastion_ip" {}
variable "galaxy_instance_type" { 
  default = "t3.xlarge" # choose the type
}

