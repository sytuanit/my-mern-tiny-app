variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "my-tiny-app"
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file (leave empty to use default)"
  type        = string
  default     = ""
}

variable "kube_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "minikube"
}

variable "docker_registry" {
  description = "Docker registry URL or 'localhost' for local images"
  type        = string
  default     = "localhost"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "image_pull_policy" {
  description = "Image pull policy (Always, IfNotPresent, Never)"
  type        = string
  default     = "Never"  # Use local images for Minikube
}

