variable "environment" {
  description = "Environment name"
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
  description = "Docker image tag (usually from CI/CD)"
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

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = ""
}

variable "kube_context" {
  description = "Kubernetes context"
  type        = string
}

