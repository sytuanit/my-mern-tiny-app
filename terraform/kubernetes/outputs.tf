output "namespace" {
  value = kubernetes_namespace.app_namespace.metadata[0].name
}

output "app_service_name" {
  value = kubernetes_service.app.metadata[0].name
}

output "consumer_service_name" {
  value = kubernetes_service.consumer.metadata[0].name
}

output "ui_service_name" {
  value = kubernetes_service.ui.metadata[0].name
}

output "ui_nodeport" {
  value = kubernetes_service.ui.spec[0].port[0].node_port
}

output "access_ui" {
  value = "http://$(minikube ip):30002"
}

