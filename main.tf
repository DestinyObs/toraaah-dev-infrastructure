terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = "us-east-2"
}

# MAXIMUM SECURITY Security Group
resource "aws_security_group" "dev_server_sg" {
  name        = "toraaah-dev-secure-sg"
  description = "MAXIMUM SECURITY - Only SSH, HTTP, HTTPS. All database/app ports BLOCKED at firewall level."
  vpc_id      = "vpc-0e4ca218d71e01997"

  # HTTPS - Required for public web access
  ingress {
    description = "HTTPS - Public web traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP - Required for Let's Encrypt certificate validation and HTTPS redirect
  ingress {
    description = "HTTP - Lets Encrypt validation and redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH - Administrative access
  ingress {
    description = "SSH - Admin access (RESTRICT TO YOUR IP!)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 🚨 Change to YOUR_IP/32 after deployment
  }

  # Outbound - Allow all
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "toraaah-dev-secure-sg"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# IMPORT TARGET: Existing Elastic IP
resource "aws_eip" "dev_eip" {
  domain = "vpc"
  
  tags = {
    Name        = "toraaah-dev"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# IMPORT TARGET: Existing EC2 Instance
resource "aws_instance" "dev_server" {
  ami           = "ami-04f167a56786e4b09"  # Original AMI
  instance_type = "t3.medium"
  key_name      = "ToraaahProd"
  
  subnet_id              = "subnet-07070cd44e3c2571d"
  vpc_security_group_ids = [aws_security_group.dev_server_sg.id]  # Will update to new SG
  
  root_block_device {
    volume_size = 64
    volume_type = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "toraaah-dev-with-runners"
    Environment = "dev"
    ManagedBy   = "terraform"
  }

  lifecycle {
    ignore_changes = [
      ami,  # Don't replace instance if AMI changes
    ]
  }
}

# IMPORT TARGET: EIP Association
resource "aws_eip_association" "dev_eip_assoc" {
  instance_id   = aws_instance.dev_server.id
  allocation_id = aws_eip.dev_eip.id
}
