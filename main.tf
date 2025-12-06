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

# AMI IDs
locals {
  backup_ami_id = "ami-0d0e36b91e653afa2"  # Backup AMI with your setup
}

# MAXIMUM SECURITY - Only 3 ports open: 22, 80, 443
# All application ports (PostgreSQL, Redis, Elasticsearch, etc.) are BLOCKED
# They are accessed via Docker localhost bindings only
resource "aws_security_group" "dev_server_sg" {
  name        = "toraaah-dev-secure-sg"
  description = "MAXIMUM SECURITY - Only SSH, HTTP, HTTPS. All database/app ports BLOCKED at firewall level."
  vpc_id      = "vpc-0e4ca218d71e01997"

  # HTTPS - Required for public web access to dev.toraaah.com
  ingress {
    description = "HTTPS - Public web traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP - Required for Let's Encrypt certificate validation & HTTPS redirect
  ingress {
    description = "HTTP - Let's Encrypt validation & redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH - Administrative access (restrict this after deployment!)
  ingress {
    description = "SSH - Admin access (RESTRICT TO YOUR IP!)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 🚨 Change to YOUR_IP/32 after deployment
  }

  # Outbound - Allow all (required for apt updates, docker pulls, external APIs)
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
    Security    = "maximum-hardened"
    Compliance  = "AWS-abuse-remediation"
    Purpose     = "Only ports 22,80,443 - All app/db ports blocked"
  }
  
  # SECURITY NOTES:
  # ✅ Port 80 (HTTP) - Open (nginx, redirects to HTTPS)
  # ✅ Port 443 (HTTPS) - Open (nginx, serves application)
  # ✅ Port 22 (SSH) - Open (restrict to your IP after deployment)
  # 
  # ❌ Port 1935 (RTMP) - BLOCKED (nginx binds to 127.0.0.1:1935)
  # ❌ Port 8080 - BLOCKED (nginx-rtmp binds to 127.0.0.1:8080)
  # ❌ Port 5432/5433 (PostgreSQL) - BLOCKED (Docker: 127.0.0.1:5433)
  # ❌ Port 6379 (Redis) - BLOCKED (Docker: 127.0.0.1:6379)
  # ❌ Port 8000 (Django) - BLOCKED (Docker: 127.0.0.1:8000)
  # ❌ Port 9200 (Elasticsearch) - BLOCKED (not exposed)
  # ❌ Port 9300 (Elasticsearch) - BLOCKED (not exposed)
  # ❌ Ports 30000-30100 - BLOCKED (not needed)
  # ❌ Ports 3000/3001/3002 (Next.js) - BLOCKED (Docker: 127.0.0.1:300x)
  # ❌ Ports 8081/8082 (GTM) - BLOCKED (Docker: 127.0.0.1:808x)
}

# NEW EC2 Instance from Backup AMI with Secure SG
resource "aws_instance" "dev_server_new" {
  ami           = local.backup_ami_id
  instance_type = "t3.medium"
  key_name      = "ToraaahProd"
  
  subnet_id              = "subnet-07070cd44e3c2571d"
  vpc_security_group_ids = [aws_security_group.dev_server_sg.id]
  
  root_block_device {
    volume_size = 64
    volume_type = "gp3"
  }

  tags = {
    Name        = "toraaah-dev-secure"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Associate the Elastic IP with the NEW instance
resource "aws_eip_association" "dev_eip_assoc_new" {
  instance_id   = aws_instance.dev_server_new.id
  allocation_id = "eipalloc-007d71f3c3aa135b5"  # Your existing EIP
}
