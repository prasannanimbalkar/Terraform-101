variable "instance_name" {
    description = "value of name tag for ec2 instance"
    type        = string
    default     = "terraform_instance_updated"
}

variable "ec2_instance_type" {
    description = "AWS EC2 Instance type"
    type        = string
    default     = "t2.micro"
}