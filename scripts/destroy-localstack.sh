#!/bin/bash

set -e

echo "🗑️  Destroying LocalStack EC2 infrastructure"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Destroy Terraform resources
echo -e "${YELLOW}Destroying Terraform resources...${NC}"
cd terraform/localstack

if [ -d ".terraform" ]; then
    terraform destroy -auto-approve \
      -var="docker_registry=localhost" \
      -var="mongodb_uri=mongodb://mongodb:27017/my-tiny-app" \
      -var="kafka_broker=kafka:9093" \
      -var="app_api_url=http://app:3000"
else
    echo -e "${RED}⚠️  Terraform not initialized. Nothing to destroy.${NC}"
fi

cd ../../

# Stop infrastructure services
echo -e "${YELLOW}Stopping infrastructure services...${NC}"
docker-compose -f docker-compose.localstack.yml down

# Clean up localstack data
echo -e "${YELLOW}Cleaning up LocalStack data...${NC}"
rm -rf ./localstack-data

echo -e "${GREEN}✅ Cleanup complete!${NC}"

