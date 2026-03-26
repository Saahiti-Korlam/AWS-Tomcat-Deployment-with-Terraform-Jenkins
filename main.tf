terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Security Group
resource "aws_security_group" "sahi_sg" {
  name        = "sahi-security-group"
  description = "Allow SSH and app access"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App Port"
    from_port   = 8080
    to_port     = 8080
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

# EC2 Instance
resource "aws_instance" "sahi_ec2" {
  ami           = "ami-0f559c3642608c138"
  instance_type = "t3.small"
  key_name      = "sahi-ec2"

  vpc_security_group_ids = [aws_security_group.sahi_sg.id]

  root_block_device {
    volume_size = 12
    volume_type = "gp3"
  }

  tags = {
    Name = "sahi-ec2-instance"
  }
}
