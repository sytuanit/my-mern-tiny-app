output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Public Subnet ID"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.app_sg.id
}

output "iam_instance_profile_name" {
  description = "IAM Instance Profile name"
  value       = aws_iam_instance_profile.ec2_profile.name
}

