terraform {
  # Remote backend with s3 bucket e dynamodb
  backend "s3" {
    bucket         = "nome"
    key            = "percorso bucket .../terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "" 
    encrypt        = true              
  }


  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.22.1" # https://registry.terraform.io/providers/hashicorp/aws/6.22.1
    }
  }
}

provider "aws" {
  region     = var.aws_region 
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# ubuntu o Rocky
data "aws_ami" "rocky_9" {
  most_recent = true

  filter {
    name = "name"
    values = [""] # check on ec2 -> amis e poi public images
  }
  owner = [""] # id o aws marketplace?
}


#keypair
resource "aws_key_pair" "vm_key" {
  key_name   = "vm_key"
  public_key = var.public_ssh_key
}

# VPC and subnet
resource "aws_vpc" "vpc" {
  cidr_block = "10.10.0.0/16"
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "${var.aws_region}a"
}

# secuity group
#resource "aws_security_group" "galaxy_instance" {
#  name = "galaxy_instance_security_group"
#}

# Ssh only from Bastion
resource "aws_security_group" "ssh_internal" {
  name   = "ssh_internal"
  vpc_id = aws_vpc.vpc.id
  description = "allow SSH only from Bastion"

  ingress {
    from_port   = 22 
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# HTTP
resource "aws_security_group" "http_access" {
  name        = "http_access"
  vpc_id      = aws_vpc.vpc.id
  description = "Allow HTTP"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.bastion_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# GALAXY insatnce
resource "aws_instance" "galaxy_vm" {
  ami                    = data.aws_ami.rocky_9.id
  instance_type          = "t3.xlarge"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [
    aws_security_group.ssh_internal.id,
    aws_security_group.http_access.id,
  ]

  key_name = aws_key_pair.vm_key.key_name
  user_data = file(".../cloudinit.sh")
  }
}
# outputs
