# Stop all Docker containers except LocalStack
# This script stops all application containers but keeps LocalStack running

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Stop All Containers (Keep LocalStack)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Get all containers
Write-Host "1. Checking running containers..." -ForegroundColor Yellow
$allContainers = docker ps --format "{{.Names}}" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Error: Could not list containers" -ForegroundColor Red
    exit 1
}

$containersToStop = @()
foreach ($container in $allContainers) {
    if ($container -and $container -ne "localstack") {
        $containersToStop += $container
    }
}

if ($containersToStop.Count -eq 0) {
    Write-Host "   OK: No containers to stop (only LocalStack is running)" -ForegroundColor Green
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  Complete!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
    exit 0
}

Write-Host "   Found $($containersToStop.Count) container(s) to stop:" -ForegroundColor White
foreach ($container in $containersToStop) {
    Write-Host "   - $container" -ForegroundColor Gray
}

Write-Host ""

# Stop using docker-compose
Write-Host "2. Stopping containers via docker-compose..." -ForegroundColor Yellow
$ErrorActionPreference = "SilentlyContinue"
docker-compose down 2>&1 | Out-Null
$ErrorActionPreference = "Stop"

# Stop individual containers if any remain
Write-Host "3. Stopping remaining containers..." -ForegroundColor Yellow
foreach ($container in $containersToStop) {
    Write-Host "   Stopping: $container..." -ForegroundColor Gray
    $ErrorActionPreference = "SilentlyContinue"
    docker stop $container 2>&1 | Out-Null
    $ErrorActionPreference = "Stop"
}

Write-Host ""
Write-Host "4. Verifying containers stopped..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
$remainingContainers = docker ps --format "{{.Names}}" 2>&1
$stillRunning = @()
foreach ($container in $remainingContainers) {
    if ($container -and $container -ne "localstack") {
        $stillRunning += $container
    }
}

if ($stillRunning.Count -eq 0) {
    Write-Host "   OK: All containers stopped (LocalStack still running)" -ForegroundColor Green
} else {
    Write-Host "   Warning: Some containers still running:" -ForegroundColor Yellow
    foreach ($container in $stillRunning) {
        Write-Host "   - $container" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "LocalStack is still running:" -ForegroundColor Cyan
$localstackRunning = docker ps --format "{{.Names}}" 2>&1 | Select-String -Pattern "^localstack$" -Quiet
if ($localstackRunning) {
    Write-Host "   OK: LocalStack container is running" -ForegroundColor Green
} else {
    Write-Host "   Warning: LocalStack container not found" -ForegroundColor Yellow
}

