# Infrastructure Deployment - Deploy once, rarely changes
# MongoDB, Kafka, Zookeeper

module "infrastructure" {
  source = "../../../modules/infrastructure"

  # Environment
  environment = var.environment
  namespace   = var.namespace
  name_prefix = var.name_prefix

  # Config
  config = var.config

  # Kubernetes
  kubeconfig_path = var.kubeconfig_path
  kube_context    = var.kube_context
}

# Outputs
output "namespace" {
  description = "Kubernetes namespace"
  value       = module.infrastructure.namespace
}

output "configmap_name" {
  description = "ConfigMap name"
  value       = module.infrastructure.configmap_name
}

output "mongodb_service_name" {
  description = "MongoDB service name"
  value       = module.infrastructure.mongodb_service_name
}

output "kafka_service_name" {
  description = "Kafka service name"
  value       = module.infrastructure.kafka_service_name
}

