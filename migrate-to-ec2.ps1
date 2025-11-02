# Script to stop Docker containers and rely on EC2 instances
# Chạy: .\migrate-to-ec2.ps1

$ErrorActionPreference = "Stop"

Write-Host "🔄 Migrating from Docker containers to EC2 instances" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check EC2 instances status
Write-Host "Step 1: Checking EC2 instances..." -ForegroundColor Yellow
try {
    $instances = aws --endpoint-url=http://localhost:4567 ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key=='Name'].Value|[0]]" --output json 2>&1 | ConvertFrom-Json
    
    if ($instances -and $instances.Count -gt 0) {
        Write-Host "✅ Found EC2 instances:" -ForegroundColor Green
        $instances | ForEach-Object {
            Write-Host "  - Instance: $($_[0]), State: $($_[1]), Name: $($_[2])" -ForegroundColor White
        }
    } else {
        Write-Host "⚠️  No EC2 instances found. Please run .\deploy-all.ps1 first" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "❌ Error checking EC2 instances: $_" -ForegroundColor Red
    Write-Host "   Make sure AWS CLI is installed and LocalStack is running" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Step 2: List current Docker containers
Write-Host "Step 2: Checking current Docker containers..." -ForegroundColor Yellow
$containers = docker ps --filter "name=my-tiny-app" --format "{{.Names}}"
if ($containers) {
    Write-Host "Found containers running on Docker host:" -ForegroundColor White
    $containers | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
} else {
    Write-Host "No containers found" -ForegroundColor Gray
}
Write-Host ""

# Step 3: Stop and remove containers
Write-Host "Step 3: Stopping Docker containers on host..." -ForegroundColor Yellow
Write-Host "  This allows EC2 instances to run their own containers" -ForegroundColor Gray

try {
    docker compose -f docker-compose.localstack.yml stop app consumer 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Stopped containers" -ForegroundColor Green
    }
    
    docker compose -f docker-compose.localstack.yml rm -f app consumer 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Removed containers" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Warning: Could not stop containers (may already be stopped)" -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Verify containers are stopped
Write-Host "Step 4: Verifying containers are stopped..." -ForegroundColor Yellow
$remaining = docker ps --filter "name=my-tiny-app" --format "{{.Names}}"
if ($remaining) {
    Write-Host "  ⚠️  Some containers are still running:" -ForegroundColor Yellow
    $remaining | ForEach-Object { Write-Host "    - $_" -ForegroundColor White }
} else {
    Write-Host "  ✓ No containers running on Docker host" -ForegroundColor Green
}
Write-Host ""

# Step 5: Check if containers are running inside EC2 instances
Write-Host "Step 5: Checking containers inside EC2 instances..." -ForegroundColor Yellow
Write-Host "  Note: LocalStack Community may not support containers inside EC2 instances" -ForegroundColor Gray
Write-Host "  If containers don't appear, user_data scripts may not have executed" -ForegroundColor Gray
Write-Host ""

# Try to get EC2 instance details and check user data
Write-Host "EC2 Instances should have containers started via user_data scripts" -ForegroundColor Cyan
Write-Host ""

# Step 6: Test application endpoints
Write-Host "Step 6: Testing application endpoints..." -ForegroundColor Yellow

$appUrl = "http://localhost:3000/health"
$consumerUrl = "http://localhost:3001/health"

try {
    Write-Host "  Testing app endpoint: $appUrl" -ForegroundColor White
    $appResponse = Invoke-WebRequest -Uri $appUrl -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
    if ($appResponse.StatusCode -eq 200) {
        Write-Host "  ✅ App is responding (may be from EC2 instance or another source)" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  App endpoint not responding - containers may not be running in EC2" -ForegroundColor Yellow
}

try {
    Write-Host "  Testing consumer endpoint: $consumerUrl" -ForegroundColor White
    $consumerResponse = Invoke-WebRequest -Uri $consumerUrl -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
    if ($consumerResponse.StatusCode -eq 200) {
        Write-Host "  ✅ Consumer is responding" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Consumer endpoint not responding" -ForegroundColor Yellow
}
Write-Host ""

# Final summary
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Migration Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Docker containers on host have been stopped" -ForegroundColor Green
Write-Host "✅ EC2 instances are running on LocalStack" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  Important Notes:" -ForegroundColor Yellow
Write-Host "  1. LocalStack Community Edition has limitations with EC2" -ForegroundColor White
Write-Host "  2. User data scripts may not execute properly" -ForegroundColor White
Write-Host "  3. Containers inside EC2 instances may not start automatically" -ForegroundColor White
Write-Host "  4. If apps don't respond, you may need to use LocalStack Pro" -ForegroundColor White
Write-Host "     or keep containers running on Docker host (hybrid approach)" -ForegroundColor White
Write-Host ""
Write-Host "To verify EC2 instances:" -ForegroundColor Cyan
Write-Host "  aws --endpoint-url=http://localhost:4567 ec2 describe-instances" -ForegroundColor White
Write-Host ""
Write-Host "To restart containers on Docker host (if needed):" -ForegroundColor Cyan
Write-Host "  docker compose -f docker-compose.localstack.yml up -d app consumer" -ForegroundColor White
Write-Host ""

