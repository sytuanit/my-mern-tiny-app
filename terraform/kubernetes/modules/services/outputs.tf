output "app_service_name" {
  description = "App service name"
  value       = kubernetes_service.app.metadata[0].name
}

output "consumer_service_name" {
  description = "Consumer service name"
  value       = kubernetes_service.consumer.metadata[0].name
}

output "ui_service_name" {
  description = "UI service name"
  value       = kubernetes_service.ui.metadata[0].name
}

output "ui_nodeport" {
  description = "UI NodePort"
  value       = kubernetes_service.ui.spec[0].port[0].node_port
}

