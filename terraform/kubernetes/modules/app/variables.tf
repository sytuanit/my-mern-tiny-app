variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "docker_registry" {
  description = "Docker registry URL"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
}

variable "image_pull_policy" {
  description = "Image pull policy"
  type        = string
}

variable "app_replicas" {
  description = "Number of app replicas"
  type        = number
}

variable "consumer_replicas" {
  description = "Number of consumer replicas"
  type        = number
}

variable "ui_replicas" {
  description = "Number of UI replicas"
  type        = number
}

variable "app_resources" {
  description = "App resource requests and limits"
  type = object({
    requests = object({
      memory = string
      cpu    = string
    })
    limits = object({
      memory = string
      cpu    = string
    })
  })
}

variable "consumer_resources" {
  description = "Consumer resource requests and limits"
  type = object({
    requests = object({
      memory = string
      cpu    = string
    })
    limits = object({
      memory = string
      cpu    = string
    })
  })
}

variable "ui_resources" {
  description = "UI resource requests and limits"
  type = object({
    requests = object({
      memory = string
      cpu    = string
    })
    limits = object({
      memory = string
      cpu    = string
    })
  })
}

variable "config" {
  description = "ConfigMap values"
  type = object({
    NODE_ENV       = string
    MONGODB_URI    = string
    KAFKA_BROKER   = string
    KAFKA_TOPIC    = string
    KAFKA_GROUP_ID = string
    APP_API_URL   = string
    API_URL       = string
  })
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = ""
}

variable "kube_context" {
  description = "Kubernetes context"
  type        = string
}

