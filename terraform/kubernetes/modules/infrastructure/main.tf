# Infrastructure Module - MongoDB, Kafka, Zookeeper
# Deploy once, rarely changes

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

# Namespace
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.namespace
    labels = {
      name        = var.namespace
      environment = var.environment
    }
  }
}

# ConfigMap
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "${var.name_prefix}app-config"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      environment = var.environment
      component   = "infrastructure"
    }
  }

  data = {
    MONGODB_URI       = var.config.MONGODB_URI
    KAFKA_BROKER     = var.config.KAFKA_BROKER
    KAFKA_TOPIC      = var.config.KAFKA_TOPIC
    KAFKA_GROUP_ID   = var.config.KAFKA_GROUP_ID
    APP_API_URL      = var.config.APP_API_URL
    API_URL          = var.config.API_URL
    NODE_ENV         = var.config.NODE_ENV
    PORT_APP         = "3000"
    PORT_CONSUMER    = "3001"
    PORT_UI          = "3002"
  }
}

# MongoDB StatefulSet
resource "kubernetes_stateful_set" "mongodb" {
  metadata {
    name      = "${var.name_prefix}mongodb"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app         = "mongodb"
      environment = var.environment
      component   = "infrastructure"
    }
  }

  spec {
    service_name = "${var.name_prefix}mongodb-headless"
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
            value = var.namespace
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
    name      = "${var.name_prefix}mongodb"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app         = "mongodb"
      environment = var.environment
      component   = "infrastructure"
    }
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
    name      = "${var.name_prefix}mongodb-headless"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app         = "mongodb"
      environment = var.environment
      component   = "infrastructure"
    }
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
    name      = "${var.name_prefix}zookeeper"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app         = "zookeeper"
      environment = var.environment
      component   = "infrastructure"
    }
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
    name      = "${var.name_prefix}zookeeper"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app         = "zookeeper"
      environment = var.environment
      component   = "infrastructure"
    }
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
    name      = "${var.name_prefix}kafka"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app         = "kafka"
      environment = var.environment
      component   = "infrastructure"
    }
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
            value = "${var.name_prefix}zookeeper:2181"
          }

          env {
            name  = "KAFKA_ADVERTISED_LISTENERS"
            value = "PLAINTEXT://localhost:9092,PLAINTEXT_INTERNAL://${var.name_prefix}kafka:9093"
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
    name      = "${var.name_prefix}kafka"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app         = "kafka"
      environment = var.environment
      component   = "infrastructure"
    }
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

