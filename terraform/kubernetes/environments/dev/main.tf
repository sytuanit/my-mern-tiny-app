# Development Environment
# Uses base module from ../modules/

module "app" {
  source = "../../modules/app"

  # Environment
  environment = var.environment
  namespace   = var.namespace
  name_prefix = var.name_prefix

  # Images
  docker_registry  = var.docker_registry
  image_tag        = var.image_tag
  image_pull_policy = var.image_pull_policy

  # Replicas
  app_replicas      = var.app_replicas
  consumer_replicas = var.consumer_replicas
  ui_replicas       = var.ui_replicas

  # Resources
  app_resources      = var.app_resources
  consumer_resources = var.consumer_resources
  ui_resources       = var.ui_resources

  # Config
  config = var.config

  # Kubernetes
  kubeconfig_path = var.kubeconfig_path
  kube_context    = var.kube_context
}

# Outputs
output "namespace" {
  value = module.app.namespace
}

output "app_service_name" {
  value = module.app.app_service_name
}

output "consumer_service_name" {
  value = module.app.consumer_service_name
}

output "ui_service_name" {
  value = module.app.ui_service_name
}

output "ui_nodeport" {
  value = module.app.ui_nodeport
}

