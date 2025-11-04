variable "environment" {
  type = string
}

variable "namespace" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "config" {
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
  type    = string
  default = ""
}

variable "kube_context" {
  type = string
}

