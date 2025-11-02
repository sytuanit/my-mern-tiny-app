# PowerShell Makefile alternative for Windows
# Usage: .\Makefile.ps1 <command>

param(
    [Parameter(Position=0)]
    [string]$Command = "help"
)

function Show-Help {
    Write-Host ""
    Write-Host "Usage: .\Makefile.ps1 <command>" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available commands:" -ForegroundColor Yellow
    Write-Host "  localstack-up      Start LocalStack and infrastructure services" -ForegroundColor White
    Write-Host "  localstack-down    Stop LocalStack and infrastructure services" -ForegroundColor White
    Write-Host "  build              Build Docker images for apps" -ForegroundColor White
    Write-Host "  deploy             Deploy apps to LocalStack EC2" -ForegroundColor White
    Write-Host "  destroy            Destroy LocalStack infrastructure" -ForegroundColor White
    Write-Host "  clean              Clean up all data and containers" -ForegroundColor White
    Write-Host "  test-localstack    Test LocalStack connectivity" -ForegroundColor White
    Write-Host "  list-instances     List EC2 instances in LocalStack" -ForegroundColor White
    Write-Host "  help               Show this help message" -ForegroundColor White
    Write-Host ""
}

function Start-LocalStack {
    Write-Host "🚀 Starting LocalStack and infrastructure..." -ForegroundColor Cyan
    docker-compose -f docker-compose.localstack.yml up -d localstack mongodb kafka zookeeper
    Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    Write-Host "✅ Services started!" -ForegroundColor Green
}

function Stop-LocalStack {
    Write-Host "🛑 Stopping LocalStack and infrastructure..." -ForegroundColor Cyan
    docker-compose -f docker-compose.localstack.yml down
    Write-Host "✅ Services stopped!" -ForegroundColor Green
}

function Build-Images {
    Write-Host "🔨 Building Docker images..." -ForegroundColor Cyan
    docker build -t my-tiny-app:latest ./my-tiny-app
    docker build -t my-tiny-app-consumer:latest ./my-tiny-app-consumer
    Write-Host "✅ Images built!" -ForegroundColor Green
}

function Deploy-ToLocalStack {
    & ".\scripts\deploy-to-localstack.ps1"
}

function Destroy-LocalStack {
    & ".\scripts\destroy-localstack.sh"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Bash script not available, using PowerShell alternative..." -ForegroundColor Yellow
        # PowerShell alternative
        Write-Host "🗑️  Destroying LocalStack EC2 infrastructure" -ForegroundColor Cyan
        Set-Location terraform/localstack
        if (Test-Path ".terraform") {
            terraform destroy -auto-approve `
              -var="docker_registry=localhost" `
              -var="mongodb_uri=mongodb://mongodb:27017/my-tiny-app" `
              -var="kafka_broker=kafka:9093" `
              -var="app_api_url=http://app:3000"
        } else {
            Write-Host "⚠️  Terraform not initialized. Nothing to destroy." -ForegroundColor Yellow
        }
        Set-Location ../..
        docker-compose -f docker-compose.localstack.yml down
        if (Test-Path "./localstack-data") {
            Remove-Item -Recurse -Force "./localstack-data"
        }
        Write-Host "✅ Cleanup complete!" -ForegroundColor Green
    }
}

function Clean-All {
    Write-Host "🧹 Cleaning up..." -ForegroundColor Cyan
    docker-compose -f docker-compose.localstack.yml down -v
    if (Test-Path "./localstack-data") {
        Remove-Item -Recurse -Force "./localstack-data"
    }
    if (Test-Path "$env:TEMP/my-tiny-app.tar") {
        Remove-Item "$env:TEMP/my-tiny-app.tar"
    }
    if (Test-Path "$env:TEMP/my-tiny-app-consumer.tar") {
        Remove-Item "$env:TEMP/my-tiny-app-consumer.tar"
    }
    Write-Host "✅ Cleanup complete!" -ForegroundColor Green
}

function Test-LocalStack {
    Write-Host "🧪 Testing LocalStack..." -ForegroundColor Cyan
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:4567/_localstack/health" -UseBasicParsing
        $response.Content | ConvertFrom-Json | ConvertTo-Json
    } catch {
        Write-Host "⚠️  LocalStack is not responding" -ForegroundColor Yellow
    }
    
    try {
        $result = aws --endpoint-url=http://localhost:4567 ec2 describe-instances 2>&1
        if ($LASTEXITCODE -eq 0 -and $result) {
            aws --endpoint-url=http://localhost:4567 ec2 describe-instances --output table
        } else {
            Write-Host "⚠️  AWS CLI not configured or no instances found" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  AWS CLI not configured or no instances found" -ForegroundColor Yellow
    }
}

function List-Instances {
    Write-Host "📋 Listing EC2 instances..." -ForegroundColor Cyan
    try {
        # Escape single quotes properly for PowerShell
        $query = "Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key=='Name'].Value|[0],PublicIpAddress]"
        aws --endpoint-url=http://localhost:4567 ec2 describe-instances --query $query --output table
    } catch {
        Write-Host "⚠️  AWS CLI not configured or no instances found" -ForegroundColor Yellow
        Write-Host "   Make sure AWS CLI is installed and LocalStack is running" -ForegroundColor Yellow
    }
}

# Main command router
switch ($Command.ToLower()) {
    "localstack-up" { Start-LocalStack }
    "localstack-down" { Stop-LocalStack }
    "build" { Build-Images }
    "deploy" { Deploy-ToLocalStack }
    "destroy" { Destroy-LocalStack }
    "clean" { Clean-All }
    "test-localstack" { Test-LocalStack }
    "list-instances" { List-Instances }
    "help" { Show-Help }
    default {
        Write-Host "❌ Unknown command: $Command" -ForegroundColor Red
        Write-Host ""
        Show-Help
        exit 1
    }
}

