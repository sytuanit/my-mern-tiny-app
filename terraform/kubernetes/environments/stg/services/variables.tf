variable "environment" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "docker_registry" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "image_pull_policy" {
  type = string
}

variable "app_replicas" {
  type = number
}

variable "consumer_replicas" {
  type = number
}

variable "ui_replicas" {
  type = number
}

variable "app_resources" {
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
  type    = string
  default = ""
}

variable "kube_context" {
  type = string
}

