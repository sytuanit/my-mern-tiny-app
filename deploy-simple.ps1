# Simple deployment without Terraform - just run apps in docker-compose
# Chạy: .\deploy-simple.ps1

$ErrorActionPreference = "Stop"

Write-Host "🚀 Simple deployment to LocalStack (without Terraform EC2)" -ForegroundColor Cyan
Write-Host ""

# Step 1: Start infrastructure services
Write-Host "Step 1: Starting infrastructure services..." -ForegroundColor Yellow
docker compose -f docker-compose.localstack.yml up -d mongodb kafka zookeeper
Start-Sleep -Seconds 10
Write-Host "✅ Infrastructure services started" -ForegroundColor Green
Write-Host ""

# Step 2: Build Docker images
Write-Host "Step 2: Building Docker images..." -ForegroundColor Yellow
Write-Host "  Building my-tiny-app..." -ForegroundColor White
docker build -t my-tiny-app:latest ./my-tiny-app
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build my-tiny-app" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ my-tiny-app built" -ForegroundColor Green

Write-Host "  Building my-tiny-app-consumer..." -ForegroundColor White
$null = docker build -t my-tiny-app-consumer:latest ./my-tiny-app-consumer 2>&1
$buildSuccess = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String "my-tiny-app-consumer:latest"
if (-not $buildSuccess) {
    Write-Host "❌ Failed to build my-tiny-app-consumer" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ my-tiny-app-consumer built" -ForegroundColor Green
Write-Host ""

# Step 3: Start applications (as containers, not EC2)
Write-Host "Step 3: Starting applications..." -ForegroundColor Yellow
docker compose -f docker-compose.localstack.yml up -d app consumer
Start-Sleep -Seconds 5
Write-Host "✅ Applications started" -ForegroundColor Green
Write-Host ""

# Step 4: Check status
Write-Host "Step 4: Checking application status..." -ForegroundColor Yellow
docker ps --filter "name=my-tiny-app" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
Write-Host ""

# Step 5: Test endpoints
Write-Host "Step 5: Testing endpoints..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

try {
    $health = Invoke-WebRequest -Uri "http://localhost:3000/api/items" -UseBasicParsing -TimeoutSec 5
    Write-Host "  ✓ API (my-tiny-app) is responding" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  API (my-tiny-app) not ready yet" -ForegroundColor Yellow
}

try {
    $consumerHealth = Invoke-WebRequest -Uri "http://localhost:3001/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "  ✓ Consumer (my-tiny-app-consumer) is responding" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  Consumer (my-tiny-app-consumer) not ready yet" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Services:" -ForegroundColor Cyan
Write-Host "  - API: http://localhost:3000/api/items" -ForegroundColor White
Write-Host "  - Consumer: http://localhost:3001/health" -ForegroundColor White
Write-Host "  - LocalStack: http://localhost:4567/_localstack/health" -ForegroundColor White
Write-Host "  - MongoDB: mongodb://localhost:27017" -ForegroundColor White
Write-Host "  - Kafka: localhost:9092" -ForegroundColor White
Write-Host ""
Write-Host "Note: Apps are running as Docker containers, not EC2 instances." -ForegroundColor Yellow
Write-Host "      To deploy to LocalStack EC2, you need Terraform installed." -ForegroundColor Yellow

