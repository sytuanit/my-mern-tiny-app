# Check if local Docker containers are running before provisioning to LocalStack
# This helps avoid confusion about which services are being used

param(
    [Parameter(Mandatory=$false)]
    [switch]$AutoStop = $false
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Check Local Docker Containers" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check for running containers
$containers = docker ps --format "{{.Names}}" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: Could not check Docker containers" -ForegroundColor Yellow
    exit 0
}

$relevantContainers = @()
$containerNames = @(
    "my-tiny-app",
    "my-tiny-app-consumer",
    "my-tiny-app-ui",
    "my-tiny-app-mongodb",
    "my-tiny-app-kafka",
    "my-tiny-app-zookeeper"
)

foreach ($line in $containers) {
    if ($line) {
        foreach ($name in $containerNames) {
            if ($line -match $name) {
                $relevantContainers += $line
            }
        }
    }
}

if ($relevantContainers.Count -eq 0) {
    Write-Host "OK: No local containers running" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can safely provision to LocalStack EC2." -ForegroundColor White
    exit 0
}

Write-Host "Warning: Found $($relevantContainers.Count) local container(s) running:" -ForegroundColor Yellow
Write-Host ""
foreach ($container in $relevantContainers) {
    Write-Host "   - $container" -ForegroundColor White
}

Write-Host ""
Write-Host "Impact Analysis:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   OK: Port Conflict: NO" -ForegroundColor Green
Write-Host "      Services on LocalStack EC2 run inside EC2 instance," -ForegroundColor Gray
Write-Host "      not on your local machine, so no port conflicts." -ForegroundColor Gray
Write-Host ""
Write-Host "   Warning: Potential Confusion: YES" -ForegroundColor Yellow
Write-Host "      - Local services: http://localhost:3000, :3001, :3002" -ForegroundColor Gray
Write-Host "      - EC2 services: Access via EC2 instance IP/ports" -ForegroundColor Gray
Write-Host "      - You might accidentally test the wrong endpoints" -ForegroundColor Gray
Write-Host ""
Write-Host "   OK: MongoDB Connection: NO ISSUE" -ForegroundColor Green
Write-Host "      EC2 services use container names for connection" -ForegroundColor Gray
Write-Host "      not localhost, so no conflicts." -ForegroundColor Gray

Write-Host ""
Write-Host "Recommendations:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   1. Keep running (safe):" -ForegroundColor White
Write-Host "      - Local containers for development/testing" -ForegroundColor Gray
Write-Host "      - EC2 containers for production-like testing" -ForegroundColor Gray
Write-Host ""
Write-Host "   2. Stop local containers (recommended):" -ForegroundColor White
Write-Host "      - Avoid confusion about which services you're testing" -ForegroundColor Gray
Write-Host "      - Free up local resources" -ForegroundColor Gray
Write-Host ""

if ($AutoStop) {
    Write-Host "Stopping local containers..." -ForegroundColor Yellow
    docker-compose down 2>&1 | Out-Null
    Write-Host "OK: Local containers stopped" -ForegroundColor Green
} else {
    $choice = Read-Host "Stop local containers now? (y/n)"
    if ($choice -eq "y" -or $choice -eq "Y") {
        Write-Host ""
        Write-Host "Stopping local containers..." -ForegroundColor Yellow
        docker-compose down 2>&1 | Out-Null
        Write-Host "OK: Local containers stopped" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Info: Keeping local containers running" -ForegroundColor Cyan
        Write-Host "   Make sure you know which endpoints you're testing!" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Check Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
