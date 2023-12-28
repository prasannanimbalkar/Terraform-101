#provider Block
provider "aws" {
  profile = "user1"
  region = "us-east-1"
}

# Resouirces Block
resource "aws_instance" "app_server" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = var.ec2_instance_type

  tags = {
    Name = var.instance_name
  }
}