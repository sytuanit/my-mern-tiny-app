# Infrastructure Deployment - Staging Environment

module "infrastructure" {
  source = "../../../modules/infrastructure"

  environment = var.environment
  namespace   = var.namespace
  name_prefix = var.name_prefix
  config      = var.config
  kubeconfig_path = var.kubeconfig_path
  kube_context    = var.kube_context
}

output "namespace" {
  value = module.infrastructure.namespace
}

output "configmap_name" {
  value = module.infrastructure.configmap_name
}

output "mongodb_service_name" {
  value = module.infrastructure.mongodb_service_name
}

output "kafka_service_name" {
  value = module.infrastructure.kafka_service_name
}

