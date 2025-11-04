#!/bin/bash

set -e

# Install Docker
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create docker-compose file for infrastructure services
cat > /opt/docker-compose-infra.yml <<'INFRA_EOF'
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: mongodb
    restart: unless-stopped
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    environment:
      MONGO_INITDB_DATABASE: my-tiny-app

  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    container_name: zookeeper
    restart: unless-stopped
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    container_name: kafka
    restart: unless-stopped
    ports:
      - "9092:9092"
      - "9093:9093"
    depends_on:
      - zookeeper
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092,PLAINTEXT_INTERNAL://kafka:9093
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_INTERNAL:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT_INTERNAL
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"

volumes:
  mongodb_data:
INFRA_EOF

# Start infrastructure services
docker-compose -f /opt/docker-compose-infra.yml up -d

# Wait for services to be ready
sleep 15

# Pull Docker images (or load from tar if available)
docker pull ${docker_registry}/my-tiny-app:${app_image_tag} || echo "App image not found, will use local"
docker pull ${docker_registry}/my-tiny-app-consumer:${consumer_image_tag} || echo "Consumer image not found, will use local"
docker pull ${docker_registry}/my-tiny-app-ui:${ui_image_tag} || echo "UI image not found, will use local"

# Create docker-compose file for application services
cat > /opt/docker-compose-apps.yml <<APPS_EOF
version: '3.8'

services:
  app:
    image: ${docker_registry}/my-tiny-app:${app_image_tag}
    container_name: my-tiny-app
    restart: unless-stopped
    ports:
      - "${app_port}:${app_port}"
    environment:
      PORT: ${app_port}
      MONGODB_URI: ${mongodb_uri}
      KAFKA_BROKER: ${kafka_broker}
      KAFKA_TOPIC: ${kafka_topic}
      NODE_ENV: ${node_env}
      AWS_REGION: ${aws_region}
      AWS_ENDPOINT_URL: ${aws_endpoint_url}
    depends_on:
      - mongodb
      - kafka
    networks:
      - app-network

  consumer:
    image: ${docker_registry}/my-tiny-app-consumer:${consumer_image_tag}
    container_name: my-tiny-app-consumer
    restart: unless-stopped
    ports:
      - "${consumer_port}:${consumer_port}"
    environment:
      PORT: ${consumer_port}
      MONGODB_URI: ${mongodb_uri}
      KAFKA_BROKER: ${kafka_broker}
      KAFKA_TOPIC: ${kafka_topic}
      KAFKA_GROUP_ID: ${kafka_group_id}
      MY_TINY_APP_API_URL: ${app_api_url}
      NODE_ENV: ${node_env}
      AWS_REGION: ${aws_region}
      AWS_ENDPOINT_URL: ${aws_endpoint_url}
    depends_on:
      - mongodb
      - kafka
      - app
    networks:
      - app-network

  ui:
    image: ${docker_registry}/my-tiny-app-ui:${ui_image_tag}
    container_name: my-tiny-app-ui
    restart: unless-stopped
    ports:
      - "${ui_port}:${ui_port}"
    environment:
      PORT: ${ui_port}
      NEXT_PUBLIC_API_URL: ${api_url}
      API_URL: ${api_url}
      NODE_ENV: ${node_env}
    depends_on:
      - app
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
APPS_EOF

# Start application services
docker-compose -f /opt/docker-compose-apps.yml up -d

# Log deployment status
echo "Deployment completed at $(date)" >> /var/log/my-tiny-app-deployment.log

# List running containers for verification
echo "=== Running Containers ===" >> /var/log/my-tiny-app-deployment.log
docker ps >> /var/log/my-tiny-app-deployment.log 2>&1

# Log container status
echo "=== Container Status ===" >> /var/log/my-tiny-app-deployment.log
docker-compose -f /opt/docker-compose-infra.yml ps >> /var/log/my-tiny-app-deployment.log 2>&1
docker-compose -f /opt/docker-compose-apps.yml ps >> /var/log/my-tiny-app-deployment.log 2>&1

