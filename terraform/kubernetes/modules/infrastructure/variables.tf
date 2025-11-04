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

