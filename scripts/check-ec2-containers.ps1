# Check containers running on LocalStack EC2 instance
# This script helps verify that containers are running on the EC2 instance

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "stg")]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [string]$InstanceId = ""
)

$ErrorActionPreference = "Stop"

# Set AWS credentials for LocalStack
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"
$env:AWS_DEFAULT_REGION = "us-east-1"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Check EC2 Instance Containers" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check LocalStack health
Write-Host "1. Checking LocalStack health..." -ForegroundColor Yellow
try {
    $health = Invoke-WebRequest -Uri "http://localhost:4567/_localstack/health" -UseBasicParsing -ErrorAction Stop
    Write-Host "   OK: LocalStack is running" -ForegroundColor Green
}
catch {
    Write-Host "   Error: LocalStack is not responding!" -ForegroundColor Red
    exit 1
}

# Step 2: Get instance ID
if (-not $InstanceId) {
    Write-Host ""
    Write-Host "2. Getting instance ID from Terraform state..." -ForegroundColor Yellow
    $stateFile = "terraform/localstack/environments/$Environment/services/terraform.tfstate"
    if (Test-Path $stateFile) {
        $state = Get-Content $stateFile | ConvertFrom-Json
        if ($state.outputs -and $state.outputs.instance_id -and $state.outputs.instance_id.value) {
            $InstanceId = $state.outputs.instance_id.value
            Write-Host "   OK: Found instance ID: $InstanceId" -ForegroundColor Green
        } else {
            Write-Host "   Warning: Could not find instance_id in state" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   Warning: Terraform state file not found" -ForegroundColor Yellow
    }
    
    # If still no instance ID, try to list instances
    if (-not $InstanceId) {
        Write-Host ""
        Write-Host "   Listing EC2 instances..." -ForegroundColor Yellow
        try {
            $instancesJson = aws --endpoint-url=http://localhost:4567 --region us-east-1 ec2 describe-instances --output json 2>&1
            if ($LASTEXITCODE -eq 0) {
                $instances = $instancesJson | ConvertFrom-Json
                $runningInstances = @()
                foreach ($reservation in $instances.Reservations) {
                    foreach ($instance in $reservation.Instances) {
                        if ($instance.State.Name -eq "running" -or $instance.State.Name -eq "pending") {
                            $runningInstances += $instance.InstanceId
                        }
                    }
                }
                if ($runningInstances.Count -gt 0) {
                    $InstanceId = $runningInstances[0]
                    Write-Host "   OK: Using instance: $InstanceId" -ForegroundColor Green
                }
            }
        }
        catch {
            Write-Host "   Error: Could not list instances" -ForegroundColor Red
        }
    }
}

if (-not $InstanceId) {
    Write-Host ""
    Write-Host "Error: No EC2 instance found!" -ForegroundColor Red
    Write-Host "Please deploy services first:" -ForegroundColor Yellow
    Write-Host "  .\scripts\provision-localstack-infra.ps1 -Environment $Environment -DeployServices" -ForegroundColor Gray
    exit 1
}

# Step 3: Get instance details
Write-Host ""
Write-Host "3. Getting EC2 instance details..." -ForegroundColor Yellow
try {
    $instanceJson = aws --endpoint-url=http://localhost:4567 --region us-east-1 ec2 describe-instances --instance-ids $InstanceId --output json 2>&1
    if ($LASTEXITCODE -eq 0) {
        $instanceData = $instanceJson | ConvertFrom-Json
        $instance = $instanceData.Reservations[0].Instances[0]
        
        Write-Host ""
        Write-Host "   Instance Information:" -ForegroundColor Cyan
        Write-Host "   - Instance ID: $($instance.InstanceId)" -ForegroundColor White
        Write-Host "   - State: $($instance.State.Name)" -ForegroundColor White
        Write-Host "   - Instance Type: $($instance.InstanceType)" -ForegroundColor White
        if ($instance.PublicIpAddress) {
            Write-Host "   - Public IP: $($instance.PublicIpAddress)" -ForegroundColor White
        }
        if ($instance.PrivateIpAddress) {
            Write-Host "   - Private IP: $($instance.PrivateIpAddress)" -ForegroundColor White
        }
        
        if ($instance.State.Name -ne "running") {
            Write-Host ""
            Write-Host "   Warning: Instance is not in running state!" -ForegroundColor Yellow
            Write-Host "   Containers may not be running yet." -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Host "   Error: Could not get instance details" -ForegroundColor Red
}

# Step 4: Note about containers
Write-Host ""
Write-Host "4. Container Information:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Note: LocalStack EC2 instances are simulated and may not support" -ForegroundColor Gray
Write-Host "   direct SSH access or container inspection." -ForegroundColor Gray
Write-Host ""
Write-Host "   Expected containers on EC2 instance:" -ForegroundColor Cyan
Write-Host "   - mongodb (port 27017)" -ForegroundColor White
Write-Host "   - kafka (ports 9092, 9093)" -ForegroundColor White
Write-Host "   - zookeeper (port 2181)" -ForegroundColor White
Write-Host "   - my-tiny-app (port 3000)" -ForegroundColor White
Write-Host "   - my-tiny-app-consumer (port 3001)" -ForegroundColor White
Write-Host "   - my-tiny-app-ui (port 3002)" -ForegroundColor White
Write-Host ""

# Step 5: Check if services are accessible (if ports are exposed)
Write-Host "5. Checking service accessibility..." -ForegroundColor Yellow
Write-Host ""
Write-Host "   Note: To access services, you need to use the EC2 instance IP." -ForegroundColor Gray
Write-Host "   However, LocalStack EC2 may not expose ports to localhost." -ForegroundColor Gray
Write-Host ""
Write-Host "   To verify containers are running:" -ForegroundColor Cyan
Write-Host "   1. Check LocalStack Desktop for instance status" -ForegroundColor White
Write-Host "   2. Check Terraform outputs for instance IP" -ForegroundColor White
Write-Host "   3. Review user_data.sh logs if available" -ForegroundColor White
Write-Host ""

# Step 6: Show Terraform outputs if available
Write-Host "6. Terraform Outputs:" -ForegroundColor Yellow
$stateFile = "terraform/localstack/environments/$Environment/services/terraform.tfstate"
if (Test-Path $stateFile) {
    try {
        $state = Get-Content $stateFile | ConvertFrom-Json
        if ($state.outputs) {
            Write-Host ""
            if ($state.outputs.instance_id) {
                Write-Host "   Instance ID: $($state.outputs.instance_id.value)" -ForegroundColor White
            }
            if ($state.outputs.instance_public_ip) {
                Write-Host "   Public IP: $($state.outputs.instance_public_ip.value)" -ForegroundColor White
            }
            if ($state.outputs.instance_private_ip) {
                Write-Host "   Private IP: $($state.outputs.instance_private_ip.value)" -ForegroundColor White
            }
        }
    }
    catch {
        Write-Host "   Warning: Could not read Terraform outputs" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Check Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: LocalStack EC2 instances are simulated." -ForegroundColor Yellow
Write-Host "Containers run inside the EC2 instance, but direct access may be limited." -ForegroundColor Gray
Write-Host ""
Write-Host "To verify deployment:" -ForegroundColor Cyan
Write-Host "1. Check LocalStack Desktop for instance status" -ForegroundColor White
Write-Host "2. Check that user_data.sh executed successfully" -ForegroundColor White
Write-Host "3. Services should be accessible via EC2 instance IP (if configured)" -ForegroundColor White

