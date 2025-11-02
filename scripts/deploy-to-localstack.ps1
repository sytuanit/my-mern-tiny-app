# PowerShell script for Windows
# Deploy my-tiny-app and my-tiny-app-consumer to LocalStack EC2

$ErrorActionPreference = "Stop"

Write-Host "🚀 Deploying my-tiny-app and my-tiny-app-consumer to LocalStack EC2" -ForegroundColor Cyan

# Check if LocalStack is running
Write-Host "`nChecking LocalStack status..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:4567/_localstack/health" -UseBasicParsing
    Write-Host "✅ LocalStack is running" -ForegroundColor Green
} catch {
    Write-Host "❌ LocalStack is not running. Please start it first:" -ForegroundColor Red
    Write-Host "   docker-compose -f docker-compose.localstack.yml up -d localstack" -ForegroundColor Yellow
    Write-Host "   Note: LocalStack now runs on port 4567 (changed from 4566)" -ForegroundColor Yellow
    exit 1
}

# Start infrastructure services
Write-Host "`nStarting infrastructure services..." -ForegroundColor Yellow
docker-compose -f docker-compose.localstack.yml up -d mongodb kafka zookeeper

# Wait for services to be ready
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Build Docker images
Write-Host "`nBuilding Docker images..." -ForegroundColor Yellow
docker build -t my-tiny-app:latest ./my-tiny-app
docker build -t my-tiny-app-consumer:latest ./my-tiny-app-consumer

# Save images as tar files for EC2 instances
Write-Host "Saving Docker images..." -ForegroundColor Yellow
docker save my-tiny-app:latest -o "$env:TEMP/my-tiny-app.tar"
docker save my-tiny-app-consumer:latest -o "$env:TEMP/my-tiny-app-consumer.tar"

# Initialize Terraform
Write-Host "`nInitializing Terraform..." -ForegroundColor Yellow
Set-Location terraform/localstack
terraform init

# Plan Terraform
Write-Host "`nPlanning Terraform deployment..." -ForegroundColor Yellow
terraform plan `
  -var="docker_registry=localhost" `
  -var="mongodb_uri=mongodb://mongodb:27017/my-tiny-app" `
  -var="kafka_broker=kafka:9093" `
  -var="app_api_url=http://app:3000"

# Apply Terraform
Write-Host "`nApplying Terraform configuration..." -ForegroundColor Yellow
terraform apply -auto-approve `
  -var="docker_registry=localhost" `
  -var="mongodb_uri=mongodb://mongodb:27017/my-tiny-app" `
  -var="kafka_broker=kafka:9093" `
  -var="app_api_url=http://app:3000"

# Get outputs
Write-Host "`n✅ Deployment complete!" -ForegroundColor Green
Write-Host "`nDeployment Summary:" -ForegroundColor Green
terraform output

Set-Location ../..

Write-Host "`n🎉 Deployment successful!" -ForegroundColor Green
Write-Host "`nTo check LocalStack resources:" -ForegroundColor Cyan
Write-Host "  aws --endpoint-url=http://localhost:4566 ec2 describe-instances" -ForegroundColor White
Write-Host "`nTo access the applications:" -ForegroundColor Cyan
Write-Host "  API: http://localhost:3000" -ForegroundColor White
Write-Host "  Consumer: http://localhost:3001" -ForegroundColor White

