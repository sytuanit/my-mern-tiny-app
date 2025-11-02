output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "app_instance_id" {
  description = "EC2 Instance ID for my-tiny-app"
  value       = aws_instance.app.id
}

output "app_instance_public_ip" {
  description = "Public IP of my-tiny-app instance"
  value       = aws_instance.app.public_ip
}

output "consumer_instance_id" {
  description = "EC2 Instance ID for my-tiny-app-consumer"
  value       = aws_instance.consumer.id
}

output "consumer_instance_public_ip" {
  description = "Public IP of my-tiny-app-consumer instance"
  value       = aws_instance.consumer.public_ip
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.app_sg.id
}

