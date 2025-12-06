output "new_instance_id" {
  description = "The ID of the NEW secure EC2 instance"
  value       = aws_instance.dev_server_new.id
}

output "new_instance_public_ip" {
  description = "The public IP address of the NEW instance (via EIP)"
  value       = "52.14.115.188"
}

output "ami_id" {
  description = "The AMI ID used for the NEW instance"
  value       = local.backup_ami_id
}

output "security_group_id" {
  description = "The ID of the NEW secure security group"
  value       = aws_security_group.dev_server_sg.id
}
