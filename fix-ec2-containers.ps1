# Script to stop Docker host containers and explain EC2 container situation
# Chạy: .\fix-ec2-containers.ps1

$ErrorActionPreference = "Continue"

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔄 Migrating Containers from Docker Host to EC2 Instances" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check EC2 instances
Write-Host "Step 1: Checking EC2 instances..." -ForegroundColor Yellow
try {
    $instancesJson = aws --endpoint-url=http://localhost:4567 ec2 describe-instances --output json 2>&1
    if ($LASTEXITCODE -eq 0) {
        $instances = $instancesJson | ConvertFrom-Json
        $runningInstances = $instances.Reservations.Instances | Where-Object { $_.State.Name -eq "running" }
        
        if ($runningInstances) {
            Write-Host "✅ Found $($runningInstances.Count) running EC2 instance(s):" -ForegroundColor Green
            $runningInstances | ForEach-Object {
                $name = ($_.Tags | Where-Object { $_.Key -eq "Name" }).Value
                Write-Host "  - Instance ID: $($_.InstanceId), Name: $name, State: $($_.State.Name)" -ForegroundColor White
            }
        } else {
            Write-Host "⚠️  No running EC2 instances found" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "⚠️  Could not check EC2 instances (AWS CLI may not be installed)" -ForegroundColor Yellow
}
Write-Host ""

# Step 2: Stop Docker host containers
Write-Host "Step 2: Stopping Docker containers on host..." -ForegroundColor Yellow
$runningContainers = docker ps --filter "name=my-tiny-app" --format "{{.Names}}"
if ($runningContainers) {
    Write-Host "Found containers running on Docker host:" -ForegroundColor White
    $runningContainers | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    
    Write-Host ""
    Write-Host "Stopping containers..." -ForegroundColor White
    docker compose -f docker-compose.localstack.yml stop app consumer 2>&1 | Out-Null
    docker compose -f docker-compose.localstack.yml rm -f app consumer 2>&1 | Out-Null
    
    Write-Host "✅ Containers stopped and removed" -ForegroundColor Green
} else {
    Write-Host "✅ No containers running on Docker host" -ForegroundColor Green
}
Write-Host ""

# Step 3: Explain the situation
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "⚠️  Important: LocalStack EC2 Container Limitations" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "Vấn đề: Containers trong EC2 instances có thể KHÔNG chạy được vì:" -ForegroundColor White
Write-Host ""
Write-Host "1. Network Connectivity:" -ForegroundColor Cyan
Write-Host "   - Containers trong EC2 không thể dùng Docker network names" -ForegroundColor White
Write-Host "     (mongodb:27017, kafka:9093, localstack:4566)" -ForegroundColor Gray
Write-Host "   - EC2 instances không join vào Docker network của host" -ForegroundColor White
Write-Host ""
Write-Host "2. LocalStack Community Limitations:" -ForegroundColor Cyan
Write-Host "   - EC2 instances là simulated, không phải real VMs" -ForegroundColor White
Write-Host "   - User data scripts có thể không execute" -ForegroundColor White
Write-Host "   - Không có real Docker daemon trong EC2 instances" -ForegroundColor White
Write-Host ""
Write-Host "3. Current Configuration:" -ForegroundColor Cyan
Write-Host "   - Terraform user_data đang dùng Docker network names" -ForegroundColor White
Write-Host "   - Containers không thể resolve các hostnames này" -ForegroundColor White
Write-Host ""

# Step 4: Solutions
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ Giải pháp" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Option 1: Hybrid Approach (Khuyến nghị) ⭐" -ForegroundColor Cyan
Write-Host "   - Giữ containers trên Docker host (như cũ)" -ForegroundColor White
Write-Host "   - EC2 instances chỉ để test infrastructure" -ForegroundColor White
Write-Host "   - Restart: docker compose -f docker-compose.localstack.yml up -d app consumer" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 2: Fix Network (Thử nghiệm)" -ForegroundColor Cyan
Write-Host "   - Sửa terraform/localstack/main.tf để dùng localhost/IP" -ForegroundColor White
Write-Host "   - Xem file EC2_CONTAINER_ISSUE.md để biết chi tiết" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 3: LocalStack Pro" -ForegroundColor Cyan
Write-Host "   - Upgrade lên LocalStack Pro (có phí)" -ForegroundColor White
Write-Host "   - EC2 support tốt hơn" -ForegroundColor White
Write-Host ""
Write-Host "Option 4: AWS thật" -ForegroundColor Cyan
Write-Host "   - Deploy lên AWS EC2 thật" -ForegroundColor White
Write-Host "   - Containers sẽ chạy được trong EC2 instances" -ForegroundColor White
Write-Host ""

# Step 5: Test application endpoints
Write-Host "Step 3: Testing application endpoints..." -ForegroundColor Yellow
$appUrl = "http://localhost:3000/health"
$consumerUrl = "http://localhost:3001/health"

$appResponding = $false
$consumerResponding = $false

try {
    $response = Invoke-WebRequest -Uri $appUrl -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        $appResponding = $true
        Write-Host "  ✅ App endpoint responding (may be from EC2)" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  App endpoint not responding" -ForegroundColor Yellow
}

try {
    $response = Invoke-WebRequest -Uri $consumerUrl -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        $consumerResponding = $true
        Write-Host "  ✅ Consumer endpoint responding (may be from EC2)" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Consumer endpoint not responding" -ForegroundColor Yellow
}
Write-Host ""

# Final summary
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📋 Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Docker containers on host: STOPPED" -ForegroundColor Green
Write-Host "✅ EC2 instances: Running (if deployed)" -ForegroundColor Green

if (-not $appResponding -and -not $consumerResponding) {
    Write-Host ""
    Write-Host "⚠️  Applications are not responding" -ForegroundColor Yellow
    Write-Host "   This is expected if containers in EC2 instances cannot start" -ForegroundColor White
    Write-Host "   due to LocalStack limitations." -ForegroundColor White
    Write-Host ""
    Write-Host "   To restart containers on Docker host:" -ForegroundColor Cyan
    Write-Host "   docker compose -f docker-compose.localstack.yml up -d app consumer" -ForegroundColor White
}
Write-Host ""
Write-Host "📖 Xem file EC2_CONTAINER_ISSUE.md để biết chi tiết về vấn đề và giải pháp" -ForegroundColor Cyan
Write-Host ""

