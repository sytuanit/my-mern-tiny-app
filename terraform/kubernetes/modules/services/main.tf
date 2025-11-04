# Services Module - App, Consumer, UI
# Deploy when code changes (on merge to dev/stg branches)

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path != "" ? var.kubeconfig_path : null
  config_context = var.kube_context
}

# Data source để reference ConfigMap từ infrastructure
data "kubernetes_config_map" "app_config" {
  metadata {
    name      = var.configmap_name
    namespace = var.namespace
  }
}

# my-tiny-app Deployment
resource "kubernetes_deployment" "app" {
  metadata {
    name      = "${var.name_prefix}my-tiny-app"
    namespace = var.namespace
    labels = {
      app         = "my-tiny-app"
      environment = var.environment
      component   = "service"
    }
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = {
        app = "my-tiny-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-tiny-app"
        }
      }

      spec {
        container {
          name  = "my-tiny-app"
          image = "${var.docker_registry}/my-tiny-app:${var.image_tag}"
          image_pull_policy = var.image_pull_policy

          port {
            container_port = 3000
            name          = "http"
          }

          env {
            name = "PORT"
            value_from {
              config_map_key_ref {
                name = data.kubernetes_config_map.app_config.metadata[0].name
                key  = "PORT_APP"
              }
            }
          }

          env {
            name = "MONGODB_URI"
            value_from {
              config_map_key_ref {
                name = data.kubernetes_config_map.app_config.metadata[0].name
                key  = "MONGODB_URI"
              }
            }
          }

          env {
            name = "KAFKA_BROKER"
            value_from {
              config_map_key_ref {
                name = data.kubernetes_config_map.app_config.metadata[0].name
                key  = "KAFKA_BROKER"
              }
            }
          }

          env {
            name = "KAFKA_TOPIC"
            value_from {
              config_map_key_ref {
                name = data.kubernetes_config_map.app_config.metadata[0].name
                key  = "KAFKA_TOPIC"
              }
            }
          }

          env {
            name = "NODE_ENV"
            value_from {
              config_map_key_ref {
                name = data.kubernetes_config_map.app_config.metadata[0].name
                key  = "NODE_ENV"
              }
            }
          }

          resources {
            requests = {
              memory = var.app_resources.requests.memory
              cpu    = var.app_resources.requests.cpu
            }
            limits = {
              memory = var.app_resources.limits.memory
              cpu    = var.app_resources.limits.cpu
            }
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

# my-tiny-app Service
resource "kubernetes_service" "app" {
  metadata {
    name      = "${var.name_prefix}my-tiny-app-service"
    namespace = var.namespace
    labels = {
      app         = "my-tiny-app"
      environment = var.environment
      component   = "service"
    }
  }

  spec {
    type = "ClusterIP"

    port {
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
      name        = "http"
    }

    selector = {
      app = "my-tiny-app"
    }
  }
}

# my-tiny-app-consumer Deployment
resource "kubernetes_deployment" "consumer" {
  metadata {
    name      = "${var.name_prefix}my-tiny-app-consumer"
    namespace = var.namespace
    labels = {
      app         = "my-tiny-app-consumer"
      environment = var.environment
      component   = "service"
    }
  }

  spec {
    replicas = var.consumer_replicas

    selector {
      match_labels = {
        app = "my-tiny-app-consumer"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-tiny-app-consumer"
        }
      }

      spec {
        container {
          name  = "my-tiny-app-consumer"
          image = "${var.docker_registry}/my-tiny-app-consumer:${var.image_tag}"
          image_pull_policy = var.image_pull_policy

          port {
            container_port = 3001
            name          = "http"
          }

          env {
            name = "PORT"
            value_from {
              config_map_key_ref {
                name = data.kubernetes_config_map.app_config.metadata[0].name
                key  = "PORT_CONSUMER"
              }
            }
          }

          env {
            name = "MONGODB_URI"
            value_from {
              config_map_key_ref {
                name = data.kubernetes_config_map.app_config.metadata[0].name
                key  = "MONGODB_URI"
              }
            }
          }

          env {
            name = "KAFKA_BROKER"
            value_from {
              config_map_key_ref {
                name = data.kubernetes_config_map.app_config.metadata[0].name
                key  = "KAFKA_BROKER"
              }
            }
          }

          env {
            name = "KAFKA_TOPIC"
            value_from {
              config_map_key_ref {
                name = data.kubernetes_config_map.app_config.metadata[0].name
                key  = "KAFKA_TOPIC"
              }
            }
          }

          env {
            name = "KAFKA_GROUP_ID"
            value_from {
              config_map_key_ref {
                name = data.kubernetes_config_map.app_config.metadata[0].name
                key  = "KAFKA_GROUP_ID"
              }
            }
          }

          env {
            name = "MY_TINY_APP_API_URL"
            value_from {
              config_map_key_ref {
                name = data.kubernetes_config_map.app_config.metadata[0].name
                key  = "APP_API_URL"
              }
            }
          }

          env {
            name = "NODE_ENV"
            value_from {
              config_map_key_ref {
                name = data.kubernetes_config_map.app_config.metadata[0].name
                key  = "NODE_ENV"
              }
            }
          }

          resources {
            requests = {
              memory = var.consumer_resources.requests.memory
              cpu    = var.consumer_resources.requests.cpu
            }
            limits = {
              memory = var.consumer_resources.limits.memory
              cpu    = var.consumer_resources.limits.cpu
            }
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 3001
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3001
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

# my-tiny-app-consumer Service
resource "kubernetes_service" "consumer" {
  metadata {
    name      = "${var.name_prefix}my-tiny-app-consumer-service"
    namespace = var.namespace
    labels = {
      app         = "my-tiny-app-consumer"
      environment = var.environment
      component   = "service"
    }
  }

  spec {
    type = "ClusterIP"

    port {
      port        = 3001
      target_port = 3001
      protocol    = "TCP"
      name        = "http"
    }

    selector = {
      app = "my-tiny-app-consumer"
    }
  }
}

# my-tiny-app-ui Deployment
resource "kubernetes_deployment" "ui" {
  metadata {
    name      = "${var.name_prefix}my-tiny-app-ui"
    namespace = var.namespace
    labels = {
      app         = "my-tiny-app-ui"
      environment = var.environment
      component   = "service"
    }
  }

  spec {
    replicas = var.ui_replicas

    selector {
      match_labels = {
        app = "my-tiny-app-ui"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-tiny-app-ui"
        }
      }

      spec {
        container {
          name  = "my-tiny-app-ui"
          image = "${var.docker_registry}/my-tiny-app-ui:${var.image_tag}"
          image_pull_policy = var.image_pull_policy

          port {
            container_port = 3002
            name          = "http"
          }

          env {
            name = "PORT"
            value_from {
              config_map_key_ref {
                name = data.kubernetes_config_map.app_config.metadata[0].name
                key  = "PORT_UI"
              }
            }
          }

          env {
            name = "NEXT_PUBLIC_API_URL"
            value_from {
              config_map_key_ref {
                name = data.kubernetes_config_map.app_config.metadata[0].name
                key  = "API_URL"
              }
            }
          }

          env {
            name = "API_URL"
            value_from {
              config_map_key_ref {
                name = data.kubernetes_config_map.app_config.metadata[0].name
                key  = "API_URL"
              }
            }
          }

          env {
            name = "NODE_ENV"
            value_from {
              config_map_key_ref {
                name = data.kubernetes_config_map.app_config.metadata[0].name
                key  = "NODE_ENV"
              }
            }
          }

          resources {
            requests = {
              memory = var.ui_resources.requests.memory
              cpu    = var.ui_resources.requests.cpu
            }
            limits = {
              memory = var.ui_resources.limits.memory
              cpu    = var.ui_resources.limits.cpu
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 3002
            }
            initial_delay_seconds = 15
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 3002
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

# my-tiny-app-ui Service (NodePort)
resource "kubernetes_service" "ui" {
  metadata {
    name      = "${var.name_prefix}my-tiny-app-ui-service"
    namespace = var.namespace
    labels = {
      app         = "my-tiny-app-ui"
      environment = var.environment
      component   = "service"
    }
  }

  spec {
    type = "NodePort"

    port {
      port        = 3002
      target_port = 3002
      protocol    = "TCP"
      name        = "http"
      node_port   = 30002
    }

    selector = {
      app = "my-tiny-app-ui"
    }
  }
}

