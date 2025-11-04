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
  namespace   = data.terraform_remote_state.infrastructure.outputs.namespace
  name_prefix = var.name_prefix
  configmap_name = data.terraform_remote_state.infrastructure.outputs.configmap_name

  docker_registry  = var.docker_registry
  image_tag        = var.image_tag
  image_pull_policy = var.image_pull_policy

  app_replicas      = var.app_replicas
  consumer_replicas = var.consumer_replicas
  ui_replicas       = var.ui_replicas

  app_resources      = var.app_resources
  consumer_resources = var.consumer_resources
  ui_resources       = var.ui_resources

  kubeconfig_path = var.kubeconfig_path
  kube_context    = var.kube_context
}

output "app_service_name" {
  value = module.services.app_service_name
}

output "consumer_service_name" {
  value = module.services.consumer_service_name
}

output "ui_service_name" {
  value = module.services.ui_service_name
}

output "ui_nodeport" {
  value = module.services.ui_nodeport
}

