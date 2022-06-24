// --------------------------
// Terraform AWS Demo Environment
// When run locally use terraform.tfvars and
// via pipelines use Circleci env-var's for
// <AWS_ACCESS_KEY_ID>, <AWS_SECRET_ACCESS_KEY>
// AWS IAM should have allow permission for
// sts:*, ec2:* and other essential actions
// --------------------------

//variable "AWS_ACCESS_KEY_ID" {}
//variable "AWS_SECRET_ACCESS_KEY" {}

terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}


provider "aws" {
  region  = "eu-west-1"
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

// VPC
resource "aws_vpc" "terraform_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "Terraform Demo Vpc"
  }
}

// Gateway
resource "aws_internet_gateway" "terraform_gateway" {
  vpc_id = aws_vpc.terraform_vpc.id
  tags = {
    Name = "Terraform Demo Gateway"
  }
}

// Subnet
resource "aws_subnet" "terraform_subnet" {
  cidr_block = "10.0.0.0/24"
  vpc_id = aws_vpc.terraform_vpc.id
  map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.terraform_gateway]
  tags = {
    Name = "Terraform Demo Subnet"
  }
}

// Elastic IP
resource "aws_eip" "terraform_ip" {
  instance = aws_instance.terraform_instance.id
  vpc      = true
  tags = {
    Name = "Terraform Demo Esi"
  }
}

// Route table
resource "aws_route_table" "terraform_rtb" {
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_gateway.id
  }
  tags = {
    Name = "Terraform Demo Rtb"
  }
}

// SSH Key
resource "aws_key_pair" "terraform_key" {
  key_name = "terraform"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDgAdKscMBDy715fPChgb36SyjOHQNNTibBjdn09pQw8FrvB0L3irv9E37PlW9aaI9Cb1QQBnhbBv3HHOd7VWZ14Lx5/WmxtbsrgoBheLHt7EI78lhZXTQxGWa6lodi3AGjGtKz9R5lOq05WODXgF5faI+6krKeSjy6ANkr8ctlXOmtyp1Bg3rm6q2ZeWgxBSq+MBCjkIzHZ2LzVdPpbB+utbnU2gw0U23WmHmqZs2P0lN9yIBwgYJQGvNMM9rT6DB8v2AGmjV01Fjb0e0bDkrj/nA9INVEaBkfOPJPdAcWT7L/PhG65AP5BA8LwYW3+d+hdN5YwsWXQ5A/t75dI2Z9 jevmok@Jevs-MacBook-Pro.local"
  tags = {
    Name = "Terraform Demo Key"
  }
}

// Security Group
resource "aws_security_group" "terraform_sg" {
  name = "terraform"
  vpc_id = aws_vpc.terraform_vpc.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Terraform Demo Sg"
  }
}

// Instance
resource "aws_instance" "terraform_instance" {
  ami = "ami-0d71ea30463e0ff8d"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.terraform_subnet.id
  key_name = aws_key_pair.terraform_key.key_name
  security_groups = [aws_security_group.terraform_sg.id]
  tags = {
    Name = "Terraform Demo Instance"
  }
  user_data = <<EOF
    #! /bin/bash
    sudo yum upgrade -y
    sudo amazon-linux-extras install nginx1 -y
    sudo service nginx start
  EOF
}

output "terraform_instance_url" {
  value = aws_instance.terraform_instance.public_dns
}
