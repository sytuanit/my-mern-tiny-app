# Services Module - EC2 Instance with Docker containers
# Deploy when code changes
# All services (MongoDB, Kafka, Zookeeper, App, Consumer, UI) run on same instance

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = var.aws_region
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = var.localstack_endpoint
    s3  = var.localstack_endpoint
    iam = var.localstack_endpoint
    sts = var.localstack_endpoint
    ssm = var.localstack_endpoint
  }
}

# EC2 Instance - All services on single instance
resource "aws_instance" "app_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.iam_instance_profile_name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    docker_registry     = var.docker_registry
    app_image_tag       = var.app_image_tag
    consumer_image_tag  = var.consumer_image_tag
    ui_image_tag        = var.ui_image_tag
    mongodb_uri         = var.mongodb_uri
    kafka_broker        = var.kafka_broker
    kafka_topic         = var.kafka_topic
    kafka_group_id      = var.kafka_group_id
    app_api_url         = var.app_api_url
    api_url             = var.api_url
    node_env            = var.node_env
    aws_region          = var.aws_region
    aws_endpoint_url    = var.aws_endpoint_url
    app_port            = var.app_port
    consumer_port       = var.consumer_port
    ui_port             = var.ui_port
  }))

  tags = {
    Name        = "${var.name_prefix}my-tiny-app-server"
    Environment = var.environment
    Type        = "services"
  }
}

