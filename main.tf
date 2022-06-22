// --------------------------
// Terraform AWS Demo Environment
// <AWS_ACCESS_KEY>, <AWS_SECRET_KEY> stored against CircleCi env-var
// Account IAM should have allow permission for sts:* Actions
// --------------------------

terraform {

  cloud {}

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
  access_key = $AWS_ACCESS_KEY
  secret_key = $AWS_SECRET_KEY
}

// VPC
resource "aws_vpc" "terraform_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Terraform Demo Vpc"
  }
}

// Subnet
resource "aws_subnet" "terraform_subnet" {
  cidr_block = "10.0.0.0/24"
  vpc_id = aws_vpc.terraform_vpc.id
  tags = {
    Name = "Terraform Demo Subnet"
  }
}

// Instance
resource "aws_instance" "terraform_instance" {
  ami = "ami-0d71ea30463e0ff8d"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.terraform_subnet.id
  tags = {
    Name = "Terraform Demo Instance"
  }
}
