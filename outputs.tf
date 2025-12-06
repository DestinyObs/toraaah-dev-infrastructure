output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.dev_server.id
}

output "public_ip" {
  description = "The public IP address"
  value       = aws_eip.dev_eip.public_ip
}

output "security_group_id" {
  description = "The ID of the secure security group"
  value       = aws_security_group.dev_server_sg.id
}

output "backup_ami_id" {
  description = "The AMI ID of the backup"
  value       = "ami-0d0e36b91e653afa2"
}
