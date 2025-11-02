#!/bin/bash

set -e

echo "🚀 Deploying my-tiny-app and my-tiny-app-consumer to LocalStack EC2"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if LocalStack is running
echo -e "${YELLOW}Checking LocalStack status...${NC}"
if ! curl -s http://localhost:4566/_localstack/health > /dev/null; then
    echo -e "${RED}❌ LocalStack is not running. Please start it first:${NC}"
    echo "   docker-compose -f docker-compose.localstack.yml up -d localstack"
    exit 1
fi
echo -e "${GREEN}✅ LocalStack is running${NC}"

# Start infrastructure services
echo -e "${YELLOW}Starting infrastructure services...${NC}"
docker-compose -f docker-compose.localstack.yml up -d mongodb kafka zookeeper

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 10

# Build Docker images
echo -e "${YELLOW}Building Docker images...${NC}"
docker build -t my-tiny-app:latest ./my-tiny-app
docker build -t my-tiny-app-consumer:latest ./my-tiny-app-consumer

# Save images as tar files for EC2 instances
echo -e "${YELLOW}Saving Docker images...${NC}"
docker save my-tiny-app:latest -o /tmp/my-tiny-app.tar
docker save my-tiny-app-consumer:latest -o /tmp/my-tiny-app-consumer.tar

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
cd terraform/localstack
terraform init

# Plan Terraform
echo -e "${YELLOW}Planning Terraform deployment...${NC}"
terraform plan \
  -var="docker_registry=localhost" \
  -var="mongodb_uri=mongodb://mongodb:27017/my-tiny-app" \
  -var="kafka_broker=kafka:9093" \
  -var="app_api_url=http://app:3000"

# Apply Terraform
echo -e "${YELLOW}Applying Terraform configuration...${NC}"
terraform apply -auto-approve \
  -var="docker_registry=localhost" \
  -var="mongodb_uri=mongodb://mongodb:27017/my-tiny-app" \
  -var="kafka_broker=kafka:9093" \
  -var="app_api_url=http://app:3000"

# Get outputs
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo -e "${GREEN}Deployment Summary:${NC}"
terraform output

cd ../../

echo ""
echo -e "${GREEN}🎉 Deployment successful!${NC}"
echo ""
echo "To check LocalStack resources:"
echo "  aws --endpoint-url=http://localhost:4566 ec2 describe-instances"
echo ""
echo "To access the applications:"
echo "  API: http://localhost:3000"
echo "  Consumer: http://localhost:3001"

