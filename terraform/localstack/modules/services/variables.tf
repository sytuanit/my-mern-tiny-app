variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID (from infrastructure)"
  type        = string
}

variable "security_group_id" {
  description = "Security Group ID (from infrastructure)"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "IAM Instance Profile name (from infrastructure)"
  type        = string
}

variable "ami_id" {
  description = "AMI ID (LocalStack dummy AMI)"
  type        = string
  default     = "ami-12345678"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "docker_registry" {
  description = "Docker registry URL"
  type        = string
}

variable "app_image_tag" {
  description = "App Docker image tag"
  type        = string
}

variable "consumer_image_tag" {
  description = "Consumer Docker image tag"
  type        = string
}

variable "ui_image_tag" {
  description = "UI Docker image tag"
  type        = string
}

variable "mongodb_uri" {
  description = "MongoDB connection URI"
  type        = string
}

variable "kafka_broker" {
  description = "Kafka broker address"
  type        = string
}

variable "kafka_topic" {
  description = "Kafka topic name"
  type        = string
}

variable "kafka_group_id" {
  description = "Kafka consumer group ID"
  type        = string
}

variable "app_api_url" {
  description = "App API URL for consumer"
  type        = string
}

variable "api_url" {
  description = "API URL for UI"
  type        = string
}

variable "node_env" {
  description = "Node environment"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_endpoint_url" {
  description = "AWS endpoint URL (LocalStack)"
  type        = string
  default     = "http://localstack:4566"
}

variable "localstack_endpoint" {
  description = "LocalStack endpoint URL"
  type        = string
  default     = "http://localhost:4567"
}

variable "app_port" {
  description = "App port"
  type        = string
  default     = "3000"
}

variable "consumer_port" {
  description = "Consumer port"
  type        = string
  default     = "3001"
}

variable "ui_port" {
  description = "UI port"
  type        = string
  default     = "3002"
}

