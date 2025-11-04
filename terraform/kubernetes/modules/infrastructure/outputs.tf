output "namespace" {
  description = "Kubernetes namespace name"
  value       = kubernetes_namespace.app_namespace.metadata[0].name
}

output "configmap_name" {
  description = "ConfigMap name"
  value       = kubernetes_config_map.app_config.metadata[0].name
}

output "mongodb_service_name" {
  description = "MongoDB service name"
  value       = kubernetes_service.mongodb.metadata[0].name
}

output "kafka_service_name" {
  description = "Kafka service name"
  value       = kubernetes_service.kafka.metadata[0].name
}

output "zookeeper_service_name" {
  description = "Zookeeper service name"
  value       = kubernetes_service.zookeeper.metadata[0].name
}

