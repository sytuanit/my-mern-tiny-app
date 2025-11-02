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
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4567"
    s3  = "http://localhost:4567"
    iam = "http://localhost:4567"
    sts = "http://localhost:4567"
    ssm = "http://localhost:4567"
  }
}

# VPC for EC2 instances
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames  = true
  enable_dns_support    = true

  tags = {
    Name = "my-tiny-app-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-tiny-app-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "my-tiny-app-public-subnet"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "my-tiny-app-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for EC2 instances
resource "aws_security_group" "app_sg" {
  name        = "my-tiny-app-sg"
  description = "Security group for my-tiny-app instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Consumer HTTP"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-tiny-app-sg"
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "my-tiny-app-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "my-tiny-app-ec2-role"
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "my-tiny-app-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance for my-tiny-app
resource "aws_instance" "app" {
  ami                    = "ami-12345678" # LocalStack dummy AMI
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Install Docker
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    
    # Pull and run my-tiny-app container
    docker pull ${var.docker_registry}/my-tiny-app:latest || docker load -i /tmp/my-tiny-app.tar
    docker run -d \
      --name my-tiny-app \
      --restart unless-stopped \
      -p 3000:3000 \
      -e PORT=3000 \
      -e MONGODB_URI=${var.mongodb_uri} \
      -e KAFKA_BROKER=${var.kafka_broker} \
      -e KAFKA_TOPIC=item-events \
      -e NODE_ENV=production \
      -e AWS_REGION=us-east-1 \
      -e AWS_ENDPOINT_URL=http://localstack:4566 \
      ${var.docker_registry}/my-tiny-app:latest
  EOF
  )

  tags = {
    Name = "my-tiny-app-instance"
    Type = "app"
  }
}

# EC2 Instance for my-tiny-app-consumer
resource "aws_instance" "consumer" {
  ami                    = "ami-12345678" # LocalStack dummy AMI
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Install Docker
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    
    # Pull and run my-tiny-app-consumer container
    docker pull ${var.docker_registry}/my-tiny-app-consumer:latest || docker load -i /tmp/my-tiny-app-consumer.tar
    docker run -d \
      --name my-tiny-app-consumer \
      --restart unless-stopped \
      -p 3001:3001 \
      -e PORT=3001 \
      -e MONGODB_URI=${var.mongodb_uri} \
      -e KAFKA_BROKER=${var.kafka_broker} \
      -e KAFKA_TOPIC=item-events \
      -e KAFKA_GROUP_ID=my-tiny-app-consumer-group \
      -e MY_TINY_APP_API_URL=${var.app_api_url} \
      -e NODE_ENV=production \
      -e AWS_REGION=us-east-1 \
      -e AWS_ENDPOINT_URL=http://localstack:4566 \
      ${var.docker_registry}/my-tiny-app-consumer:latest
  EOF
  )

  tags = {
    Name = "my-tiny-app-consumer-instance"
    Type = "consumer"
  }
}

