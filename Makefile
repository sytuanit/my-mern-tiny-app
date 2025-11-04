.PHONY: help localstack-up localstack-down build deploy destroy clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

localstack-up: ## Start LocalStack and infrastructure services
	@echo "🚀 Starting LocalStack and infrastructure..."
	docker-compose -f docker-compose.localstack.yml up -d localstack mongodb kafka zookeeper
	@echo "⏳ Waiting for services to be ready..."
	@sleep 10
	@echo "✅ Services started!"

localstack-down: ## Stop LocalStack and infrastructure services
	@echo "🛑 Stopping LocalStack and infrastructure..."
	docker-compose -f docker-compose.localstack.yml down
	@echo "✅ Services stopped!"

build: ## Build Docker images for apps
	@echo "🔨 Building Docker images..."
	docker build -t my-tiny-app:latest ./my-tiny-app
	docker build -t my-tiny-app-consumer:latest ./my-tiny-app-consumer
	@echo "✅ Images built!"

deploy: ## Deploy apps to LocalStack EC2 (use Terraform)
	@echo "⚠️  Use Terraform to deploy:"
	@echo "  cd terraform/localstack && terraform apply"

destroy: ## Destroy LocalStack infrastructure (use Terraform)
	@echo "⚠️  Use Terraform to destroy:"
	@echo "  cd terraform/localstack && terraform destroy"

clean: ## Clean up all data and containers
	@echo "🧹 Cleaning up..."
	docker-compose -f docker-compose.localstack.yml down -v
	rm -rf ./localstack-data
	rm -f /tmp/my-tiny-app.tar /tmp/my-tiny-app-consumer.tar
	@echo "✅ Cleanup complete!"

test-localstack: ## Test LocalStack connectivity
	@echo "🧪 Testing LocalStack..."
	@curl -s http://localhost:4566/_localstack/health | jq .
	@aws --endpoint-url=http://localhost:4566 ec2 describe-instances 2>/dev/null || echo "⚠️  AWS CLI not configured or no instances found"

list-instances: ## List EC2 instances in LocalStack
	@aws --endpoint-url=http://localhost:4566 ec2 describe-instances \
		--query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0],PublicIpAddress]' \
		--output table || echo "⚠️  AWS CLI not configured or no instances found"

