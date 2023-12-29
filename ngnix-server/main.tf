# Defining providers we will use in this deployement
# We only need the aws provides. Terraform will retrive the aws provider from hashicorp bublic registry
provider "aws" {
  profile = "user1"
  region  = "us-east-1"
}



# First we need to create an aws VPC. We need a VPC to run EC2 ubuntu ami
# I am going to run an ami-08d70e59c07c61a3a with t2.micro instnace_type to keep things free
# ami ids change from region to region. You can find them here https://cloud-images.ubuntu.com/locator/ec2/
# Creating the VPC
# The code block below uses the aws_vpc module from the aws provider in hashicorp registry
# Documentation available here: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
resource "aws_vpc" "nginx-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  #   enable_classiclink   = "false"
  instance_tenancy = "default"
}


# Creating a public subnet
# Public subnet is required for the instances in the VPC to communicate over the internet
# Documentation is available here: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "prod-subnet-public-1" {
  vpc_id                  = aws_vpc.nginx-vpc.id // Referencing the id of the VPC from abouve code block
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true" // Makes this a public subnet
  availability_zone       = "us-east-1a"
}



# Creating an Internet Gateway
# Require for the VPC to communicate with the internet
# Documentation is available here: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "prod-igw" {
  vpc_id = aws_vpc.nginx-vpc.id
}




# Create a custom route table for public subnets
# Public subnets can reach to the internet buy using this
# Documentation is available here: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "prod-public-crt" {
  vpc_id = aws_vpc.nginx-vpc.id
  route {
    cidr_block = "0.0.0.0/0"                      //associated subnet can reach everywhere
    gateway_id = aws_internet_gateway.prod-igw.id //CRT uses this IGW to reach internet
  }
  tags = {
    Name = "prod-public-crt"
  }
}



# Route table association for the public subnets
# Documentation is available here: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "prod-crta-public-subnet-1" {
  subnet_id      = aws_subnet.prod-subnet-public-1.id
  route_table_id = aws_route_table.prod-public-crt.id
}




# Security group
# Creating this so we can SSH into the VPC and the ami instance to instal nginx port 22
# This also allow us to access the nginx server via the public ip address port 80
# Documentation is available here: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "ssh-allowed" {
  vpc_id = aws_vpc.nginx-vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // Ideally best to use your laptops IP. However if it is dynamic you will need to change this in the vpc every so often. 
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




# Setting up the EC2 instnace
# We are installing ubunto as the core OD
resource "aws_instance" "nginx_server" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  tags = {
    Name = "nginx_server"
  }
  # VPC
  subnet_id = aws_subnet.prod-subnet-public-1.id
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.ssh-allowed.id}"]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash -ex
    sudo apt-get -y install nginx
    sudo bash -c 'echo "<h1>This is my new server</h1>" > /usr/share/nginx/html/index.html'
    sudo bash -c 'echo "<h1>This is my new server</h1>" > /var/www/html/index.nginx-debian.html'
    sudo service nginx start
    EOF
}