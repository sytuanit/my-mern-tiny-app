# Provision Infrastructure and Services on LocalStack EC2
# This script deploys VPC, Security Groups, IAM, and optionally EC2 instances with services

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "stg")]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipHealthCheck = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DeployServices = $false
)

$ErrorActionPreference = "Stop"

# Get script root directory (project root)
$scriptRoot = Split-Path -Parent $PSScriptRoot
if (-not $scriptRoot) {
    # If running from different location, try to find project root
    $currentDir = Get-Location
    while ($currentDir -and -not (Test-Path (Join-Path $currentDir "scripts\provision-localstack-infra.ps1"))) {
        $parent = Split-Path -Parent $currentDir
        if ($parent -eq $currentDir) { break }
        $currentDir = $parent
    }
    if (Test-Path (Join-Path $currentDir "scripts\provision-localstack-infra.ps1")) {
        $scriptRoot = $currentDir
    } else {
        $scriptRoot = $PWD
    }
}

# Change to project root
Push-Location $scriptRoot
Write-Host "Working directory: $(Get-Location)" -ForegroundColor Gray
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Provision LocalStack Infrastructure" -ForegroundColor Cyan
Write-Host "  Environment: $Environment" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 0: Check local containers (optional warning)
Write-Host "0. Checking for local Docker containers..." -ForegroundColor Yellow
try {
    $localContainers = docker ps --format "{{.Names}}" 2>&1 | Select-String -Pattern "my-tiny-app" -Quiet
    if ($localContainers) {
        Write-Host "   ⚠️  Local containers detected" -ForegroundColor Yellow
        Write-Host "   💡 Tip: Run .\scripts\check-local-containers.ps1 to check conflicts" -ForegroundColor Cyan
        Write-Host "   (No port conflicts expected, but can cause confusion)" -ForegroundColor Gray
    } else {
        Write-Host "   ✅ No local containers running" -ForegroundColor Green
    }
} catch {
    # Ignore if docker command fails
}

Write-Host ""

# Step 1: Check LocalStack health
if (-not $SkipHealthCheck) {
    Write-Host "1. Checking LocalStack health..." -ForegroundColor Yellow
    try {
        $health = Invoke-WebRequest -Uri "http://localhost:4567/_localstack/health" -UseBasicParsing -ErrorAction Stop
        $healthJson = $health.Content | ConvertFrom-Json
        if ($healthJson.services -contains "ec2" -and $healthJson.services -contains "iam") {
            Write-Host "   ✅ LocalStack is running and EC2/IAM services are available" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  LocalStack is running but EC2/IAM services may not be fully ready" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "   ❌ LocalStack is not responding!" -ForegroundColor Red
        Write-Host "   Start LocalStack with:" -ForegroundColor Yellow
        Write-Host "   docker-compose -f docker-compose.localstack.yml up -d localstack" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   Or wait a few seconds and try again" -ForegroundColor Yellow
        exit 1
    }
}

# Step 2: Navigate to infrastructure directory
$infraDir = "terraform/localstack/environments/$Environment/infrastructure"
if (-not (Test-Path $infraDir)) {
    Write-Host "❌ Directory not found: $infraDir" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "3. Navigating to infrastructure directory..." -ForegroundColor Yellow
Push-Location $infraDir
Write-Host "   ✅ Current directory: $(Get-Location)" -ForegroundColor Green

# Step 3: Initialize Terraform
Write-Host ""
Write-Host "4. Initializing Terraform..." -ForegroundColor Yellow
try {
    terraform init
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform init failed"
    }
    Write-Host "   ✅ Terraform initialized" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ Terraform initialization failed!" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Step 4: Validate Terraform configuration
Write-Host ""
Write-Host "5. Validating Terraform configuration..." -ForegroundColor Yellow
try {
    terraform validate
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform validation failed"
    }
    Write-Host "   ✅ Configuration is valid" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ Terraform validation failed!" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Step 5: Plan
Write-Host ""
Write-Host "6. Planning infrastructure changes..." -ForegroundColor Yellow
try {
    terraform plan
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform plan failed"
    }
}
catch {
    Write-Host "   ❌ Terraform plan failed!" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Step 6: Apply
Write-Host ""
Write-Host "7. Applying infrastructure changes..." -ForegroundColor Yellow
$confirm = Read-Host "Do you want to proceed with applying? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "   ⏸️  Deployment cancelled by user" -ForegroundColor Yellow
    Pop-Location
    exit 0
}

try {
    terraform apply -auto-approve
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply failed"
    }
    Write-Host "   ✅ Infrastructure provisioned successfully!" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ Terraform apply failed!" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Step 7: Show outputs
Write-Host ""
Write-Host "8. Infrastructure outputs:" -ForegroundColor Yellow
try {
    terraform output
    Write-Host "   ✅ Outputs displayed" -ForegroundColor Green
}
catch {
    Write-Host "   ⚠️  Could not display outputs" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  ✅ Infrastructure Provision Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
# Step 8: Deploy Services if requested
if ($DeployServices) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  Deploying Services (EC2 Instance)" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Pop-Location  # Return to root from infrastructure directory
    
    $servicesDir = "terraform/localstack/environments/$Environment/services"
    if (-not (Test-Path $servicesDir)) {
        Write-Host "Error: Services directory not found: $servicesDir" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "9. Navigating to services directory..." -ForegroundColor Yellow
    Push-Location $servicesDir
    Write-Host "   OK: Current directory: $(Get-Location)" -ForegroundColor Green
    
    # Initialize Terraform for services
    Write-Host ""
    Write-Host "10. Initializing Terraform for services..." -ForegroundColor Yellow
    try {
        terraform init
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform init failed"
        }
        Write-Host "   OK: Terraform initialized" -ForegroundColor Green
    }
    catch {
        Write-Host "   Error: Terraform initialization failed!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    # Validate
    Write-Host ""
    Write-Host "11. Validating services configuration..." -ForegroundColor Yellow
    try {
        terraform validate
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform validation failed"
        }
        Write-Host "   OK: Configuration is valid" -ForegroundColor Green
    }
    catch {
        Write-Host "   Error: Terraform validation failed!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    # Plan
    Write-Host ""
    Write-Host "12. Planning services deployment..." -ForegroundColor Yellow
    try {
        terraform plan
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform plan failed"
        }
    }
    catch {
        Write-Host "   Error: Terraform plan failed!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    # Apply
    Write-Host ""
    Write-Host "13. Deploying services (creating EC2 instance)..." -ForegroundColor Yellow
    $confirm = Read-Host "Do you want to proceed with services deployment? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "   Deployment cancelled by user" -ForegroundColor Yellow
        Pop-Location
        exit 0
    }
    
    try {
        terraform apply -auto-approve
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform apply failed"
        }
        Write-Host "   OK: Services deployed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "   Error: Terraform apply failed!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    # Show outputs
    Write-Host ""
    Write-Host "14. Service outputs:" -ForegroundColor Yellow
    try {
        terraform output
        Write-Host "   OK: Outputs displayed" -ForegroundColor Green
    }
    catch {
        Write-Host "   Warning: Could not display outputs" -ForegroundColor Yellow
    }
    
    Pop-Location  # Return from services directory
    
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  Complete Deployment Finished!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "EC2 Instance has been created with:" -ForegroundColor Yellow
    Write-Host "  - MongoDB (port 27017)" -ForegroundColor White
    Write-Host "  - Kafka (ports 9092, 9093)" -ForegroundColor White
    Write-Host "  - Zookeeper (port 2181)" -ForegroundColor White
    Write-Host "  - App (port 3000)" -ForegroundColor White
    Write-Host "  - Consumer (port 3001)" -ForegroundColor White
    Write-Host "  - UI (port 3002)" -ForegroundColor White
    Write-Host ""
    Write-Host "Check LocalStack Desktop to see the EC2 instance!" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Deploy services (create EC2 instance):" -ForegroundColor White
    Write-Host "   .\scripts\provision-localstack-infra.ps1 -Environment $Environment -DeployServices" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Or manually:" -ForegroundColor White
    Write-Host "   cd terraform/localstack/environments/$Environment/services" -ForegroundColor Gray
    Write-Host "   terraform init && terraform apply" -ForegroundColor Gray
    
    Pop-Location
}

