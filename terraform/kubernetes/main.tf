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
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}

# Namespace
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# ConfigMap
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  data = {
    MONGODB_URI       = "mongodb://mongodb:27017/my-tiny-app"
    KAFKA_BROKER     = "kafka:9093"
    KAFKA_TOPIC      = "item-events"
    KAFKA_GROUP_ID   = "my-tiny-app-consumer-group"
    APP_API_URL      = "http://my-tiny-app-service:3000"
    API_URL          = "http://my-tiny-app-service:3000"
    NODE_ENV         = "production"
    PORT_APP         = "3000"
    PORT_CONSUMER    = "3001"
    PORT_UI          = "3002"
  }
}

# MongoDB StatefulSet
resource "kubernetes_stateful_set" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    service_name = "mongodb-headless"
    replicas     = 1

    selector {
      match_labels = {
        app = "mongodb"
      }
    }

    template {
      metadata {
        labels = {
          app = "mongodb"
        }
      }

      spec {
        container {
          name  = "mongodb"
          image = "mongo:7.0"

          port {
            container_port = 27017
            name          = "mongodb"
          }

          env {
            name  = "MONGO_INITDB_DATABASE"
            value = "my-tiny-app"
          }

          volume_mount {
            name       = "mongodb-data"
            mount_path = "/data/db"
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "mongodb-data"
      }

      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "1Gi"
          }
        }
      }
    }
  }
}

# MongoDB Service
resource "kubernetes_service" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    type = "ClusterIP"

    port {
      port        = 27017
      target_port = 27017
      protocol    = "TCP"
      name        = "mongodb"
    }

    selector = {
      app = "mongodb"
    }
  }
}

# MongoDB Headless Service
resource "kubernetes_service" "mongodb_headless" {
  metadata {
    name      = "mongodb-headless"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    cluster_ip = "None"

    port {
      port        = 27017
      target_port = 27017
      protocol    = "TCP"
      name        = "mongodb"
    }

    selector = {
      app = "mongodb"
    }
  }
}

# Zookeeper Deployment
resource "kubernetes_deployment" "zookeeper" {
  metadata {
    name      = "zookeeper"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "zookeeper"
      }
    }

    template {
      metadata {
        labels = {
          app = "zookeeper"
        }
      }

      spec {
        container {
          name  = "zookeeper"
          image = "confluentinc/cp-zookeeper:latest"

          port {
            container_port = 2181
            name          = "zookeeper"
          }

          env {
            name  = "ZOOKEEPER_CLIENT_PORT"
            value = "2181"
          }

          env {
            name  = "ZOOKEEPER_TICK_TIME"
            value = "2000"
          }
        }
      }
    }
  }
}

# Zookeeper Service
resource "kubernetes_service" "zookeeper" {
  metadata {
    name      = "zookeeper"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    type = "ClusterIP"

    port {
      port        = 2181
      target_port = 2181
      protocol    = "TCP"
      name        = "zookeeper"
    }

    selector = {
      app = "zookeeper"
    }
  }
}

# Kafka Deployment
resource "kubernetes_deployment" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "kafka"
      }
    }

    template {
      metadata {
        labels = {
          app = "kafka"
        }
      }

      spec {
        container {
          name  = "kafka"
          image = "confluentinc/cp-kafka:7.5.0"

          port {
            container_port = 9092
            name          = "kafka-external"
          }

          port {
            container_port = 9093
            name          = "kafka-internal"
          }

          env {
            name  = "KAFKA_BROKER_ID"
            value = "1"
          }

          env {
            name  = "KAFKA_ZOOKEEPER_CONNECT"
            value = "zookeeper:2181"
          }

          env {
            name  = "KAFKA_ADVERTISED_LISTENERS"
            value = "PLAINTEXT://localhost:9092,PLAINTEXT_INTERNAL://kafka:9093"
          }

          env {
            name  = "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP"
            value = "PLAINTEXT:PLAINTEXT,PLAINTEXT_INTERNAL:PLAINTEXT"
          }

          env {
            name  = "KAFKA_INTER_BROKER_LISTENER_NAME"
            value = "PLAINTEXT_INTERNAL"
          }

          env {
            name  = "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR"
            value = "1"
          }

          env {
            name  = "KAFKA_AUTO_CREATE_TOPICS_ENABLE"
            value = "true"
          }
        }
      }
    }
  }
}

# Kafka Service
resource "kubernetes_service" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    type = "ClusterIP"

    port {
      port        = 9092
      target_port = 9092
      protocol    = "TCP"
      name        = "kafka-external"
    }

    port {
      port        = 9093
      target_port = 9093
      protocol    = "TCP"
      name        = "kafka-internal"
    }

    selector = {
      app = "kafka"
    }
  }
}

# my-tiny-app Deployment
resource "kubernetes_deployment" "app" {
  metadata {
    name      = "my-tiny-app"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    replicas = 1

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
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "PORT_APP"
              }
            }
          }

          env {
            name = "MONGODB_URI"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "MONGODB_URI"
              }
            }
          }

          env {
            name = "KAFKA_BROKER"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "KAFKA_BROKER"
              }
            }
          }

          env {
            name = "KAFKA_TOPIC"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "KAFKA_TOPIC"
              }
            }
          }

          env {
            name = "NODE_ENV"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "NODE_ENV"
              }
            }
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "200m"
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
    name      = "my-tiny-app-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
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
    name      = "my-tiny-app-consumer"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    replicas = 1

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
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "PORT_CONSUMER"
              }
            }
          }

          env {
            name = "MONGODB_URI"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "MONGODB_URI"
              }
            }
          }

          env {
            name = "KAFKA_BROKER"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "KAFKA_BROKER"
              }
            }
          }

          env {
            name = "KAFKA_TOPIC"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "KAFKA_TOPIC"
              }
            }
          }

          env {
            name = "KAFKA_GROUP_ID"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "KAFKA_GROUP_ID"
              }
            }
          }

          env {
            name = "MY_TINY_APP_API_URL"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "APP_API_URL"
              }
            }
          }

          env {
            name = "NODE_ENV"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "NODE_ENV"
              }
            }
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "200m"
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
    name      = "my-tiny-app-consumer-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
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
    name      = "my-tiny-app-ui"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    replicas = 1

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
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "PORT_UI"
              }
            }
          }

          env {
            name = "NEXT_PUBLIC_API_URL"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "API_URL"
              }
            }
          }

          env {
            name = "API_URL"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "API_URL"
              }
            }
          }

          env {
            name = "NODE_ENV"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "NODE_ENV"
              }
            }
          }

          resources {
            requests = {
              memory = "256Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "200m"
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
    name      = "my-tiny-app-ui-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
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

