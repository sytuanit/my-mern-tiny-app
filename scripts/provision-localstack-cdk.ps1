# PowerShell script to provision LocalStack infrastructure using AWS CDK
# Supports both infrastructure and services deployment

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "stg")]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [switch]$DeployServices = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$AppImageTag = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ConsumerImageTag = "",
    
    [Parameter(Mandatory=$false)]
    [string]$UiImageTag = "",
    
    [Parameter(Mandatory=$false)]
    [string]$LocalStackEndpoint = "http://localhost:4567",
    
    [Parameter(Mandatory=$false)]
    [string]$AwsRegion = "us-east-1"
)

# Get project root directory
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $projectRoot) {
    $projectRoot = Get-Location
}

# Navigate to project root
Push-Location $projectRoot

try {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  LocalStack CDK Provisioning" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Environment: $Environment" -ForegroundColor Yellow
    Write-Host "LocalStack Endpoint: $LocalStackEndpoint" -ForegroundColor Yellow
    Write-Host ""

    # Check if CDK directory exists
    $cdkDir = Join-Path $projectRoot "cdk"
    if (-not (Test-Path $cdkDir)) {
        Write-Host "Error: CDK directory not found: $cdkDir" -ForegroundColor Red
        exit 1
    }

    # Check if LocalStack is running
    Write-Host "1. Checking LocalStack health..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "$LocalStackEndpoint/_localstack/health" -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "   OK: LocalStack is running" -ForegroundColor Green
        } else {
            Write-Host "   Warning: LocalStack health check returned status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   Error: LocalStack is not accessible at $LocalStackEndpoint" -ForegroundColor Red
        Write-Host "   Please start LocalStack first: docker-compose -f docker-compose.localstack.yml up -d" -ForegroundColor Yellow
        exit 1
    }

    # Set environment variables
    Write-Host ""
    Write-Host "2. Setting environment variables..." -ForegroundColor Yellow
    $env:ENVIRONMENT = $Environment
    $env:AWS_REGION = $AwsRegion
    $env:AWS_ACCESS_KEY_ID = "test"
    $env:AWS_SECRET_ACCESS_KEY = "test"
    $env:LOCALSTACK_ENDPOINT = $LocalStackEndpoint
    $env:AWS_ENDPOINT_URL = $LocalStackEndpoint
    Write-Host "   OK: Environment variables set" -ForegroundColor Green

    # Navigate to CDK directory
    Write-Host ""
    Write-Host "3. Navigating to CDK directory..." -ForegroundColor Yellow
    Push-Location $cdkDir
    Write-Host "   OK: Current directory: $(Get-Location)" -ForegroundColor Green

    # Install dependencies if needed
    if (-not (Test-Path "node_modules")) {
        Write-Host ""
        Write-Host "4. Installing CDK dependencies..." -ForegroundColor Yellow
        try {
            npm install
            if ($LASTEXITCODE -ne 0) {
                throw "npm install failed"
            }
            Write-Host "   OK: Dependencies installed" -ForegroundColor Green
        } catch {
            Write-Host "   Error: Failed to install dependencies!" -ForegroundColor Red
            Pop-Location
            exit 1
        }
    } else {
        Write-Host ""
        Write-Host "4. Dependencies already installed" -ForegroundColor Green
    }

    # Build CDK
    Write-Host ""
    Write-Host "5. Building CDK..." -ForegroundColor Yellow
    try {
        npm run build
        if ($LASTEXITCODE -ne 0) {
            throw "CDK build failed"
        }
        Write-Host "   OK: CDK built successfully" -ForegroundColor Green
    } catch {
        Write-Host "   Error: CDK build failed!" -ForegroundColor Red
        Pop-Location
        exit 1
    }

    # Bootstrap CDK (if needed)
    Write-Host ""
    Write-Host "6. Checking CDK bootstrap status..." -ForegroundColor Yellow
    try {
        # Try to check if bootstrap is needed by checking SSM parameter
        $bootstrapCheck = aws --endpoint-url=$LocalStackEndpoint ssm get-parameter --name "/cdk-bootstrap/hnb659fds/version" --region $AwsRegion 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "   Bootstrap required, bootstrapping CDK..." -ForegroundColor Yellow
            try {
                npx cdk bootstrap --app "npx ts-node infra/app.ts" --require-approval never
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "   Warning: Bootstrap may have failed, but continuing..." -ForegroundColor Yellow
                } else {
                    Write-Host "   OK: CDK bootstrapped successfully" -ForegroundColor Green
                }
            } catch {
                Write-Host "   Warning: Bootstrap failed, but continuing (LocalStack may not need full bootstrap)..." -ForegroundColor Yellow
            }
        } else {
            Write-Host "   OK: CDK already bootstrapped" -ForegroundColor Green
        }
    } catch {
        Write-Host "   Warning: Could not check bootstrap status, attempting bootstrap..." -ForegroundColor Yellow
        try {
            npx cdk bootstrap --app "npx ts-node infra/app.ts" --require-approval never 2>&1 | Out-Null
            Write-Host "   OK: Bootstrap attempted" -ForegroundColor Green
        } catch {
            Write-Host "   Warning: Bootstrap skipped (may not be needed for LocalStack)" -ForegroundColor Yellow
        }
    }

    # Deploy Infrastructure
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  Deploying Infrastructure Stack" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "7. Synthesizing infrastructure stack..." -ForegroundColor Yellow
    try {
        npx cdk synth InfrastructureStack --app "npx ts-node infra/app.ts"
        if ($LASTEXITCODE -ne 0) {
            throw "CDK synth failed"
        }
        Write-Host "   OK: Stack synthesized" -ForegroundColor Green
    } catch {
        Write-Host "   Error: CDK synth failed!" -ForegroundColor Red
        Pop-Location
        exit 1
    }

    Write-Host ""
    Write-Host "8. Deploying infrastructure..." -ForegroundColor Yellow
    $confirm = Read-Host "Do you want to proceed with infrastructure deployment? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "   Deployment cancelled by user" -ForegroundColor Yellow
        Pop-Location
        exit 0
    }

    try {
        npx cdk deploy InfrastructureStack --app "npx ts-node infra/app.ts" --require-approval never
        if ($LASTEXITCODE -ne 0) {
            throw "CDK deploy failed"
        }
        Write-Host "   OK: Infrastructure deployed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "   Error: Infrastructure deployment failed!" -ForegroundColor Red
        Pop-Location
        exit 1
    }

    # Deploy Services if requested
    if ($DeployServices) {
        Write-Host ""
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host "  Deploying Services Stack" -ForegroundColor Cyan
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host ""

        # Generate image tags if not provided
        if ([string]::IsNullOrWhiteSpace($AppImageTag)) {
            $shortSha = (git rev-parse --short HEAD).Trim()
            $AppImageTag = "$Environment-$shortSha"
            $ConsumerImageTag = "$Environment-$shortSha"
            $UiImageTag = "$Environment-$shortSha"
            Write-Host "8. Generated image tags from git:" -ForegroundColor Yellow
            Write-Host "   App: $AppImageTag" -ForegroundColor Gray
            Write-Host "   Consumer: $ConsumerImageTag" -ForegroundColor Gray
            Write-Host "   UI: $UiImageTag" -ForegroundColor Gray
        } else {
            Write-Host "8. Using provided image tags:" -ForegroundColor Yellow
            Write-Host "   App: $AppImageTag" -ForegroundColor Gray
            Write-Host "   Consumer: $ConsumerImageTag" -ForegroundColor Gray
            Write-Host "   UI: $UiImageTag" -ForegroundColor Gray
        }

        # Set image tag environment variables
        $env:APP_IMAGE_TAG = $AppImageTag
        $env:CONSUMER_IMAGE_TAG = $ConsumerImageTag
        $env:UI_IMAGE_TAG = $UiImageTag

        Write-Host ""
        Write-Host "10. Synthesizing services stack..." -ForegroundColor Yellow
        try {
            npx cdk synth ServicesStack --app "npx ts-node infra/app.ts"
            if ($LASTEXITCODE -ne 0) {
                throw "CDK synth failed"
            }
            Write-Host "   OK: Stack synthesized" -ForegroundColor Green
        } catch {
            Write-Host "   Error: CDK synth failed!" -ForegroundColor Red
            Pop-Location
            exit 1
        }

        Write-Host ""
        Write-Host "11. Deploying services..." -ForegroundColor Yellow
        $confirm = Read-Host "Do you want to proceed with services deployment? (yes/no)"
        if ($confirm -ne "yes") {
            Write-Host "   Deployment cancelled by user" -ForegroundColor Yellow
            Pop-Location
            exit 0
        }

        try {
            npx cdk deploy ServicesStack --app "npx ts-node infra/app.ts" --require-approval never
            if ($LASTEXITCODE -ne 0) {
                throw "CDK deploy failed"
            }
            Write-Host "   OK: Services deployed successfully!" -ForegroundColor Green
        } catch {
            Write-Host "   Error: Services deployment failed!" -ForegroundColor Red
            Pop-Location
            exit 1
        }

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
        Write-Host "   .\scripts\provision-localstack-cdk.ps1 -Environment $Environment -DeployServices" -ForegroundColor Gray
        Write-Host ""
        Write-Host "2. Or with specific image tags:" -ForegroundColor White
        Write-Host "   .\scripts\provision-localstack-cdk.ps1 -Environment $Environment -DeployServices -AppImageTag dev-abc123 -ConsumerImageTag dev-abc123 -UiImageTag dev-abc123" -ForegroundColor Gray
    }

    Pop-Location  # Return from CDK directory
} catch {
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location  # Return to project root
}

