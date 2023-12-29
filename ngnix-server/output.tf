output "instance_id" {
  description = "ID of ec2 instance"
  value       = aws_instance.nginx_server.id
}

output "instance_public_ip" {
  description = "Public IP of instance"
  value       = aws_instance.nginx_server.public_ip
}