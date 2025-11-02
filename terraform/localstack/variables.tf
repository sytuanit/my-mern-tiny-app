variable "docker_registry" {
  description = "Docker registry URL or 'localhost' for local images"
  type        = string
  default     = "localhost"
}

variable "mongodb_uri" {
  description = "MongoDB connection URI"
  type        = string
  default     = "mongodb://mongodb:27017/my-tiny-app"
}

variable "kafka_broker" {
  description = "Kafka broker address"
  type        = string
  default     = "kafka:9093"
}

variable "app_api_url" {
  description = "my-tiny-app API URL for consumer"
  type        = string
  default     = "http://app:3000"
}

