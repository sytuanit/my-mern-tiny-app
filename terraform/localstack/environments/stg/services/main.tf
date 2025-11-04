# Services Deployment - Staging Environment

data "terraform_remote_state" "infrastructure" {
  backend = "local"

  config = {
    path = "../infrastructure/terraform.tfstate"
  }
}

module "services" {
  source = "../../../modules/services"

  environment = var.environment
  name_prefix = var.name_prefix

  subnet_id                  = data.terraform_remote_state.infrastructure.outputs.subnet_id
  security_group_id          = data.terraform_remote_state.infrastructure.outputs.security_group_id
  iam_instance_profile_name = data.terraform_remote_state.infrastructure.outputs.iam_instance_profile_name

  ami_id         = var.ami_id
  instance_type  = var.instance_type

  docker_registry    = var.docker_registry
  app_image_tag      = var.app_image_tag
  consumer_image_tag = var.consumer_image_tag
  ui_image_tag       = var.ui_image_tag

  mongodb_uri    = var.mongodb_uri
  kafka_broker   = var.kafka_broker
  kafka_topic    = var.kafka_topic
  kafka_group_id = var.kafka_group_id
  app_api_url    = var.app_api_url
  api_url        = var.api_url
  node_env       = var.node_env

  aws_region         = var.aws_region
  aws_endpoint_url   = var.aws_endpoint_url
  localstack_endpoint = var.localstack_endpoint

  app_port      = var.app_port
  consumer_port = var.consumer_port
  ui_port       = var.ui_port
}

output "instance_id" {
  value = module.services.instance_id
}

output "instance_public_ip" {
  value = module.services.instance_public_ip
}

output "instance_private_ip" {
  value = module.services.instance_private_ip
}

