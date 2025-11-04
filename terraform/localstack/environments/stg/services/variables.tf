variable "environment" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "ami_id" {
  type    = string
  default = "ami-12345678"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "docker_registry" {
  type = string
}

variable "app_image_tag" {
  type = string
}

variable "consumer_image_tag" {
  type = string
}

variable "ui_image_tag" {
  type = string
}

variable "mongodb_uri" {
  type = string
}

variable "kafka_broker" {
  type = string
}

variable "kafka_topic" {
  type = string
}

variable "kafka_group_id" {
  type = string
}

variable "app_api_url" {
  type = string
}

variable "api_url" {
  type = string
}

variable "node_env" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_endpoint_url" {
  type    = string
  default = "http://localstack:4566"
}

variable "localstack_endpoint" {
  type    = string
  default = "http://localhost:4567"
}

variable "app_port" {
  type    = string
  default = "3000"
}

variable "consumer_port" {
  type    = string
  default = "3001"
}

variable "ui_port" {
  type    = string
  default = "3002"
}

