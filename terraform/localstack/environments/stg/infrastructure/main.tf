# Infrastructure Deployment - Staging Environment

module "infrastructure" {
  source = "../../../modules/infrastructure"

  environment = var.environment
  name_prefix = var.name_prefix

  aws_region         = var.aws_region
  localstack_endpoint = var.localstack_endpoint
  vpc_cidr           = var.vpc_cidr
  subnet_cidr        = var.subnet_cidr
  availability_zone   = var.availability_zone
}

output "vpc_id" {
  value = module.infrastructure.vpc_id
}

output "subnet_id" {
  value = module.infrastructure.subnet_id
}

output "security_group_id" {
  value = module.infrastructure.security_group_id
}

output "iam_instance_profile_name" {
  value = module.infrastructure.iam_instance_profile_name
}

