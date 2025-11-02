# Deploy my-tiny-app và my-tiny-app-consumer lên LocalStack EC2
# Chạy: .\deploy-all.ps1

$ErrorActionPreference = "Stop"

Write-Host "Starting deployment to LocalStack EC2" -ForegroundColor Cyan
Write-Host ""

# Step 1: Start infrastructure services
Write-Host "Step 1: Starting infrastructure services..." -ForegroundColor Yellow
docker compose -f docker-compose.localstack.yml up -d mongodb kafka zookeeper
Start-Sleep -Seconds 10
Write-Host "Infrastructure services started" -ForegroundColor Green
Write-Host ""

# Step 2: Build Docker images
Write-Host "Step 2: Building Docker images..." -ForegroundColor Yellow

# Check if images already exist
$appExists = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String "my-tiny-app:latest"
$consumerExists = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String "my-tiny-app-consumer:latest"

if (-not $appExists) {
    Write-Host "  Building my-tiny-app..." -ForegroundColor White
    docker build -t my-tiny-app:latest ./my-tiny-app
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to build my-tiny-app" -ForegroundColor Red
        exit 1
    }
    Write-Host "  my-tiny-app built" -ForegroundColor Green
} else {
    Write-Host "  my-tiny-app already exists, skipping build" -ForegroundColor Gray
}

if (-not $consumerExists) {
    Write-Host "  Building my-tiny-app-consumer..." -ForegroundColor White
    docker build -t my-tiny-app-consumer:latest ./my-tiny-app-consumer 2>&1 | Out-String | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to build my-tiny-app-consumer (exit code: $LASTEXITCODE)" -ForegroundColor Red
        Write-Host "Try building manually: docker build -t my-tiny-app-consumer:latest ./my-tiny-app-consumer" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "  my-tiny-app-consumer built" -ForegroundColor Green
} else {
    Write-Host "  my-tiny-app-consumer already exists, skipping build" -ForegroundColor Gray
}
Write-Host ""

# Step 3: Save images (for EC2 deployment)
Write-Host "Step 3: Saving Docker images..." -ForegroundColor Yellow
docker save my-tiny-app:latest -o "$env:TEMP/my-tiny-app.tar"
docker save my-tiny-app-consumer:latest -o "$env:TEMP/my-tiny-app-consumer.tar"
Write-Host "Images saved" -ForegroundColor Green
Write-Host ""

# Step 4: Check Terraform
Write-Host "Step 4: Checking Terraform..." -ForegroundColor Yellow
$terraformCmd = Get-Command terraform -ErrorAction SilentlyContinue
if (-not $terraformCmd) {
    # Try to refresh PATH and check again
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    $terraformCmd = Get-Command terraform -ErrorAction SilentlyContinue
    
    # If still not found, try to find in WinGet packages folder
    if (-not $terraformCmd) {
        $wingetPath = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages"
        if (Test-Path $wingetPath) {
            $terraformDirs = Get-ChildItem -Path $wingetPath -Filter "*Terraform*" -Directory -ErrorAction SilentlyContinue
            foreach ($dir in $terraformDirs) {
                $tfExe = Join-Path $dir.FullName "terraform.exe"
                if (Test-Path $tfExe) {
                    Write-Host "  Found Terraform in WinGet packages: $tfExe" -ForegroundColor Yellow
                    $env:Path += ";$($dir.FullName)"
                    $terraformCmd = Get-Command terraform -ErrorAction SilentlyContinue
                    if ($terraformCmd) {
                        Write-Host "  Added to PATH for this session" -ForegroundColor Green
                        break
                    }
                }
            }
        }
    }
}

if ($terraformCmd) {
    $terraformVersion = terraform --version 2>&1
    if ($LASTEXITCODE -eq 0 -or $terraformVersion) {
        $version = $terraformVersion | Select-Object -First 1
        Write-Host "  Terraform found: $version" -ForegroundColor Green
    } else {
        Write-Host "  Terraform found but error running" -ForegroundColor Yellow
    }
} else {
    Write-Host "Terraform is not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Terraform:" -ForegroundColor Yellow
    Write-Host "  winget install Hashicorp.Terraform" -ForegroundColor White
    Write-Host ""
    Write-Host "Or skip Terraform and run apps directly:" -ForegroundColor Yellow
    Write-Host "  docker compose -f docker-compose.localstack.yml up -d app consumer" -ForegroundColor Cyan
    Set-Location ../..
    exit 1
}

Set-Location terraform/localstack
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform init failed" -ForegroundColor Red
    Set-Location ../..
    exit 1
}
Write-Host "Terraform initialized" -ForegroundColor Green
Write-Host ""

# Step 5: Plan deployment
Write-Host "Step 5: Planning Terraform deployment..." -ForegroundColor Yellow
terraform plan `
  -var="docker_registry=localhost" `
  -var="mongodb_uri=mongodb://mongodb:27017/my-tiny-app" `
  -var="kafka_broker=kafka:9093" `
  -var="app_api_url=http://app:3000"
Write-Host ""

# Step 6: Apply deployment
Write-Host "Step 6: Applying Terraform configuration..." -ForegroundColor Yellow
terraform apply -auto-approve `
  -var="docker_registry=localhost" `
  -var="mongodb_uri=mongodb://mongodb:27017/my-tiny-app" `
  -var="kafka_broker=kafka:9093" `
  -var="app_api_url=http://app:3000"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform apply failed" -ForegroundColor Red
    Set-Location ../..
    exit 1
}

Write-Host ""
Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Deployment Summary:" -ForegroundColor Cyan
terraform output

Set-Location ../..

Write-Host ""
Write-Host "Checking EC2 instances..." -ForegroundColor Cyan
try {
    aws --endpoint-url=http://localhost:4567 ec2 describe-instances `
        --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' `
        --output table
} catch {
    Write-Host "Could not list instances (AWS CLI may not be configured)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Deployment successful!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  - Check LocalStack EC2 instances: aws --endpoint-url=http://localhost:4567 ec2 describe-instances" -ForegroundColor White
Write-Host "  - View logs: docker logs localstack" -ForegroundColor White
Write-Host "  - Test apps: curl http://localhost:3000/api/items" -ForegroundColor White
Write-Host ""
