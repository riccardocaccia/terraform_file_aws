terraform {
  # Remote backend with s3 bucket e dynamodb
#  backend "s3" {
#    bucket         = "nome"
#    key            = "percorso bucket .../terraform.tfstate"
#    region         = var.aws_region
#    dynamodb_table = "" 
#    encrypt        = true              
#  }


  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.22.1" # https://registry.terraform.io/providers/hashicorp/aws/6.22.1
    }
  }
}

provider "aws" {
  region     = var.aws_region 
# TODO: variabili d'ambiente
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

### data source
data "aws_ami" "rocky_9" {
  most_recent = true
  owners      = ["792107900819"]
  filter {
    name   = "name"
    values = ["Rocky-9-EC2-Base-*x86_64*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
#####

# VPC e Subnet
resource "aws_vpc" "main" {
  cidr_block = "10.10.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "${var.aws_region}a"
}

# Internet Gateway e Route Table pubblica
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "pub_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# Elastic IP + NAT gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.igw]
}

# Route table 
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "priv_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}

# Security groups
resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
# Comment if you want make the bastion accessible to everyone
    cidr_blocks = [var.bastion_ip]
    description = "SSH from admin IP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Internal SG
resource "aws_security_group" "internal_sg" {
  name   = "internal-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
    description     = "SSH only from bastion"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Keypair + Instances
resource "aws_key_pair" "vm_key" {
  key_name   = "vm_key"
  public_key = var.public_ssh_key
}

# Bastion instance (public)
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu_2204.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.vm_key.key_name
  associate_public_ip_address = true
  user_data = file("${path.module}/cloudinit-bastion.sh")
}

# VM private (galaxy)
resource "aws_instance" "galaxy_vm" {
  ami                    = data.aws_ami.rocky_9.id
  instance_type          = var.galaxy_instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.internal_sg.id]
  key_name               = aws_key_pair.vm_key.key_name
  associate_public_ip_address = false
  user_data = file("${path.module}/cloudinit.sh")

  root_block_device {
    volume_size = 50   # Dimensione in GB (imposta 50 o più)
    volume_type = "gp3" 
    delete_on_termination = true # Elimina il disco quando l'istanza viene terminata
  }
}
