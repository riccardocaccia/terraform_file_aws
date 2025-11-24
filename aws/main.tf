terraform {
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

# TODO: AMI ubuntu o Rocky

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
  availability_zone = var.aws_region
}

# TODO: secuity group, see sec_g.tf

# Ssh only from Bastion
resource "aws_security_group" "ssh_internal" {
  name   = "ssh_internal"
  vpc_id = aws_vpc.vpc.id
  description = "allow SSH only from Bastion"

  ingress {
    from_port   = 
    to_port     = 
    protocol    = "tcp"
    cidr_blocks = "212.189.202.200/32"
  }

  egress {
    from_port   = 
    to_port     = 
    protocol    = 
    cidr_blocks = 
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
    cidr_blocks = 
  }

  egress {
    from_port   = 
    to_port     = 
    protocol    = 
    cidr_blocks = 
  }
}

# GALAXY insatnce

# outputs
