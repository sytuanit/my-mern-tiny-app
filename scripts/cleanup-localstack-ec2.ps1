# Cleanup EC2 Instances on LocalStack
# This script helps remove old EC2 instances created manually or via Terraform

param(
    [Parameter(Mandatory=$false)]
    [switch]$DestroyAll = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$InstanceId = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "stg")]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [switch]$RemoveTerminated = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ResetLocalStack = $false
)

$ErrorActionPreference = "Stop"

# Set dummy AWS credentials for LocalStack (required by AWS CLI)
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"
$env:AWS_DEFAULT_REGION = "us-east-1"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Cleanup LocalStack EC2 Instances" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check LocalStack health
Write-Host "1. Checking LocalStack health..." -ForegroundColor Yellow
try {
    $health = Invoke-WebRequest -Uri "http://localhost:4567/_localstack/health" -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✅ LocalStack is running" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ LocalStack is not responding!" -ForegroundColor Red
    Write-Host "   Start LocalStack with:" -ForegroundColor Yellow
    Write-Host "   docker-compose -f docker-compose.localstack.yml up -d localstack" -ForegroundColor Yellow
    exit 1
}

# Step 2: List EC2 instances
Write-Host ""
Write-Host "2. Listing EC2 instances..." -ForegroundColor Yellow
try {
    $output = aws --endpoint-url=http://localhost:4567 --region us-east-1 ec2 describe-instances --output json 2>&1
    $instancesJson = $output | Out-String
    
    # Check if command succeeded
    if ($LASTEXITCODE -ne 0 -or $instancesJson -match "error|Error|ERROR") {
        Write-Host "   ⚠️  Could not list instances. They may not exist." -ForegroundColor Yellow
        if ($instancesJson) {
            Write-Host "   Output: $instancesJson" -ForegroundColor Gray
        }
        exit 0
    }
    
    $instances = $instancesJson | ConvertFrom-Json
    $instanceList = @()
    
    foreach ($reservation in $instances.Reservations) {
        foreach ($instance in $reservation.Instances) {
            $instanceList += @{
                InstanceId = $instance.InstanceId
                State = $instance.State.Name
                InstanceType = $instance.InstanceType
                LaunchTime = $instance.LaunchTime
            }
        }
    }
    
    if ($instanceList.Count -eq 0) {
        Write-Host "   ✅ No EC2 instances found" -ForegroundColor Green
        exit 0
    }
    
    Write-Host ""
    Write-Host "   Found $($instanceList.Count) instance(s):" -ForegroundColor White
    foreach ($inst in $instanceList) {
        $stateColor = if ($inst.State -eq "running") { "Green" } elseif ($inst.State -eq "stopped") { "Yellow" } else { "Gray" }
        Write-Host "   - Instance ID: $($inst.InstanceId)" -ForegroundColor White
        Write-Host "     State: $($inst.State)" -ForegroundColor $stateColor
        Write-Host "     Type: $($inst.InstanceType)" -ForegroundColor Gray
        Write-Host "     Launched: $($inst.LaunchTime)" -ForegroundColor Gray
        Write-Host ""
    }
}
catch {
    Write-Host "   ❌ Error listing instances: $_" -ForegroundColor Red
    Write-Host "   Error details: $($_.Exception.Message)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   Trying alternative method..." -ForegroundColor Yellow
    
    # Try alternative: Use Invoke-Expression to capture both stdout and stderr
    try {
        $cmd = "aws --endpoint-url=http://localhost:4567 --region us-east-1 ec2 describe-instances --output json"
        $instancesJson = Invoke-Expression $cmd 2>&1 | Out-String
        
        if ($instancesJson -and -not ($instancesJson -match "error|Error|ERROR|You must specify")) {
            $instances = $instancesJson | ConvertFrom-Json
            $instanceList = @()
            
            foreach ($reservation in $instances.Reservations) {
                foreach ($instance in $reservation.Instances) {
                    $instanceList += @{
                        InstanceId = $instance.InstanceId
                        State = $instance.State.Name
                        InstanceType = $instance.InstanceType
                        LaunchTime = $instance.LaunchTime
                    }
                }
            }
            
            if ($instanceList.Count -eq 0) {
                Write-Host "   ✅ No EC2 instances found" -ForegroundColor Green
                exit 0
            }
            
            Write-Host ""
            Write-Host "   Found $($instanceList.Count) instance(s):" -ForegroundColor White
            foreach ($inst in $instanceList) {
                $stateColor = if ($inst.State -eq "running") { "Green" } elseif ($inst.State -eq "stopped") { "Yellow" } else { "Gray" }
                Write-Host "   - Instance ID: $($inst.InstanceId)" -ForegroundColor White
                Write-Host "     State: $($inst.State)" -ForegroundColor $stateColor
                Write-Host "     Type: $($inst.InstanceType)" -ForegroundColor Gray
                Write-Host "     Launched: $($inst.LaunchTime)" -ForegroundColor Gray
                Write-Host ""
            }
        } else {
            Write-Host "   ⚠️  No instances found or AWS CLI error" -ForegroundColor Yellow
            Write-Host "   Output: $instancesJson" -ForegroundColor Gray
            exit 0
        }
    }
    catch {
        Write-Host "   ❌ Failed to list instances. Please check:" -ForegroundColor Red
        Write-Host "   1. LocalStack is running: curl http://localhost:4567/_localstack/health" -ForegroundColor Yellow
        Write-Host "   2. AWS CLI is installed: aws --version" -ForegroundColor Yellow
        Write-Host "   3. Try manual command: aws --endpoint-url=http://localhost:4567 --region us-east-1 ec2 describe-instances" -ForegroundColor Yellow
        exit 1
    }
}

# Step 3: Remove terminated instances if requested
if ($RemoveTerminated -or $ResetLocalStack) {
    Write-Host ""
    Write-Host "3. Removing terminated instances (Reset LocalStack)..." -ForegroundColor Yellow
    Write-Host "   WARNING: This will delete ALL LocalStack resources!" -ForegroundColor Red
    
    if (-not $ResetLocalStack) {
        $confirm = Read-Host "   Are you sure? Type 'yes' to continue"
        if ($confirm -ne "yes") {
            Write-Host "   ⏸️  Cancelled" -ForegroundColor Yellow
            exit 0
        }
    }
    
    Write-Host ""
    Write-Host "   Stopping LocalStack..." -ForegroundColor Yellow
    $ErrorActionPreference = "SilentlyContinue"
    & docker-compose -f docker-compose.localstack.yml stop localstack 2>&1 | Out-Null
    $ErrorActionPreference = "Stop"
    
    Write-Host "   Removing LocalStack container..." -ForegroundColor Yellow
    $ErrorActionPreference = "SilentlyContinue"
    & docker-compose -f docker-compose.localstack.yml rm -f localstack 2>&1 | Out-Null
    $ErrorActionPreference = "Stop"
    
    Write-Host "   Removing LocalStack data..." -ForegroundColor Yellow
    if (Test-Path "./localstack-data") {
        Remove-Item -Recurse -Force "./localstack-data"
        Write-Host "   ✅ LocalStack data removed" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  No localstack-data directory found" -ForegroundColor Yellow
    }
    
    Write-Host "   Starting LocalStack..." -ForegroundColor Yellow
    $ErrorActionPreference = "SilentlyContinue"
    & docker-compose -f docker-compose.localstack.yml up -d localstack 2>&1 | Out-Null
    $ErrorActionPreference = "Stop"
    
    Write-Host "   ⏳ Waiting for LocalStack to be ready (15 seconds)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
    
    # Verify LocalStack is running
    try {
        $health = Invoke-WebRequest -Uri "http://localhost:4567/_localstack/health" -UseBasicParsing -ErrorAction Stop
        Write-Host "   ✅ LocalStack restarted successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "   ⚠️  LocalStack may still be starting. Please wait a bit longer." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "   ✅ All terminated instances removed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  ✅ Cleanup Complete!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
    exit 0
}

# Step 4: Determine cleanup method
Write-Host "3. Cleanup options:" -ForegroundColor Yellow

if ($DestroyAll) {
    # Option 1: Destroy via Terraform (recommended if created via Terraform)
    Write-Host ""
    Write-Host "   Option A: Destroy via Terraform (recommended)" -ForegroundColor Cyan
    Write-Host "   This will destroy services and infrastructure properly" -ForegroundColor Gray
    Write-Host ""
    
    $servicesDir = "terraform/localstack/environments/$Environment/services"
    if (Test-Path $servicesDir) {
        Write-Host "   Services directory found: $servicesDir" -ForegroundColor Green
        Push-Location $servicesDir
        
        if (Test-Path "terraform.tfstate") {
            Write-Host "   Terraform state found. Destroying services..." -ForegroundColor Yellow
            terraform destroy -auto-approve
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ✅ Services destroyed successfully" -ForegroundColor Green
            }
        } else {
            Write-Host "   ⚠️  No Terraform state found in services directory" -ForegroundColor Yellow
        }
        
        Pop-Location
    }
    
    # Option 2: Terminate instances directly via AWS CLI
    Write-Host ""
    Write-Host "   Option B: Terminate instances directly via AWS CLI" -ForegroundColor Cyan
    foreach ($inst in $instanceList) {
        if ($inst.State -ne "terminated") {
            Write-Host "   Terminating instance: $($inst.InstanceId)..." -ForegroundColor Yellow
            aws --endpoint-url=http://localhost:4567 --region us-east-1 ec2 terminate-instances --instance-ids $inst.InstanceId 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ✅ Instance $($inst.InstanceId) terminated" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️  Could not terminate instance $($inst.InstanceId)" -ForegroundColor Yellow
            }
        }
    }
}
elseif ($InstanceId) {
    # Terminate specific instance
    Write-Host ""
    Write-Host "   Terminating instance: $InstanceId..." -ForegroundColor Yellow
    aws --endpoint-url=http://localhost:4567 --region us-east-1 --no-cli-pager ec2 terminate-instances --instance-ids $InstanceId 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Instance $InstanceId terminated" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Could not terminate instance $InstanceId" -ForegroundColor Red
    }
}
else {
    # Interactive mode
    Write-Host ""
    Write-Host "   Choose cleanup method:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   A) Destroy via Terraform (if created via Terraform)" -ForegroundColor White
    Write-Host "   B) Terminate instances via AWS CLI" -ForegroundColor White
    Write-Host "   C) Terminate specific instance" -ForegroundColor White
    Write-Host "   D) Remove terminated instances (Reset LocalStack data)" -ForegroundColor White
    Write-Host "   Q) Quit" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Enter choice (A/B/C/D/Q)"
    
    switch ($choice.ToUpper()) {
        "A" {
            # Terraform destroy
            $servicesDir = "terraform/localstack/environments/$Environment/services"
            if (Test-Path $servicesDir) {
                Write-Host ""
                Write-Host "   Destroying services via Terraform..." -ForegroundColor Yellow
                Push-Location $servicesDir
                
                if (Test-Path "terraform.tfstate") {
                    terraform destroy
                } else {
                    Write-Host "   ⚠️  No Terraform state found" -ForegroundColor Yellow
                }
                
                Pop-Location
            } else {
                Write-Host "   ❌ Services directory not found: $servicesDir" -ForegroundColor Red
            }
        }
        "B" {
            # Terminate all instances
            Write-Host ""
            Write-Host "   Terminating all instances..." -ForegroundColor Yellow
            foreach ($inst in $instanceList) {
                if ($inst.State -ne "terminated") {
                    Write-Host "   Terminating: $($inst.InstanceId)..." -ForegroundColor Yellow
                    aws --endpoint-url=http://localhost:4567 --region us-east-1 --no-cli-pager ec2 terminate-instances --instance-ids $inst.InstanceId 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "   ✅ Instance $($inst.InstanceId) terminated" -ForegroundColor Green
                    }
                }
            }
        }
        "C" {
            # Terminate specific instance
            Write-Host ""
            Write-Host "   Available instances:" -ForegroundColor Yellow
            for ($i = 0; $i -lt $instanceList.Count; $i++) {
                Write-Host "   [$i] $($instanceList[$i].InstanceId) - $($instanceList[$i].State)" -ForegroundColor White
            }
            Write-Host ""
            $index = Read-Host "Enter instance number"
            $selectedInst = $instanceList[[int]$index]
            
            Write-Host ""
            Write-Host "   Terminating: $($selectedInst.InstanceId)..." -ForegroundColor Yellow
            aws --endpoint-url=http://localhost:4567 --region us-east-1 --no-cli-pager ec2 terminate-instances --instance-ids $selectedInst.InstanceId 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ✅ Instance $($selectedInst.InstanceId) terminated" -ForegroundColor Green
            }
        }
        "D" {
            # Remove terminated instances by resetting LocalStack
            Write-Host ""
            Write-Host "   This will reset LocalStack and remove ALL data (including terminated instances)" -ForegroundColor Yellow
            Write-Host "   WARNING: This will delete all LocalStack resources!" -ForegroundColor Red
            $confirm = Read-Host "   Are you sure? Type 'yes' to continue"
            
            if ($confirm -eq "yes") {
                Write-Host ""
                Write-Host "   Stopping LocalStack..." -ForegroundColor Yellow
                $ErrorActionPreference = "SilentlyContinue"
                & docker-compose -f docker-compose.localstack.yml stop localstack 2>&1 | Out-Null
                $ErrorActionPreference = "Stop"
                
                Write-Host "   Removing LocalStack container..." -ForegroundColor Yellow
                $ErrorActionPreference = "SilentlyContinue"
                & docker-compose -f docker-compose.localstack.yml rm -f localstack 2>&1 | Out-Null
                $ErrorActionPreference = "Stop"
                
                Write-Host "   Removing LocalStack data..." -ForegroundColor Yellow
                if (Test-Path "./localstack-data") {
                    Remove-Item -Recurse -Force "./localstack-data"
                    Write-Host "   ✅ LocalStack data removed" -ForegroundColor Green
                }
                
                Write-Host "   Starting LocalStack..." -ForegroundColor Yellow
                $ErrorActionPreference = "SilentlyContinue"
                & docker-compose -f docker-compose.localstack.yml up -d localstack 2>&1 | Out-Null
                $ErrorActionPreference = "Stop"
                
                Write-Host "   ⏳ Waiting for LocalStack to be ready (15 seconds)..." -ForegroundColor Yellow
                Start-Sleep -Seconds 15
                
                Write-Host "   ✅ LocalStack reset complete! All terminated instances removed." -ForegroundColor Green
            } else {
                Write-Host "   ⏸️  Cancelled" -ForegroundColor Yellow
            }
        }
        "Q" {
            Write-Host "   ⏸️  Cancelled" -ForegroundColor Yellow
            exit 0
        }
        default {
            Write-Host "   ❌ Invalid choice" -ForegroundColor Red
            exit 1
        }
    }
}

# Step 5: Verify cleanup
Write-Host ""
Write-Host "4. Verifying cleanup..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
try {
    $instancesJson = aws --endpoint-url=http://localhost:4567 --region us-east-1 ec2 describe-instances --output json 2>&1
    if ($LASTEXITCODE -eq 0) {
        $instances = $instancesJson | ConvertFrom-Json
        $remainingInstances = @()
        foreach ($reservation in $instances.Reservations) {
            foreach ($instance in $reservation.Instances) {
                if ($instance.State.Name -ne "terminated") {
                    $remainingInstances += $instance.InstanceId
                }
            }
        }
        
        if ($remainingInstances.Count -eq 0) {
            Write-Host "   ✅ All instances cleaned up successfully!" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  Remaining instances: $($remainingInstances -join ', ')" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "   💡 To remove terminated instances, run:" -ForegroundColor Cyan
            Write-Host "   .\scripts\cleanup-localstack-ec2.ps1 -RemoveTerminated" -ForegroundColor Gray
        }
    }
}
catch {
    Write-Host "   ⚠️  Could not verify cleanup" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  ✅ Cleanup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: If you want to clean up infrastructure (VPC, Security Groups, etc.)," -ForegroundColor Yellow
Write-Host "run: cd terraform/localstack/environments/$Environment/infrastructure && terraform destroy" -ForegroundColor Gray
Write-Host ""
Write-Host "Note: To remove terminated instances completely, run:" -ForegroundColor Yellow
Write-Host ".\scripts\cleanup-localstack-ec2.ps1 -RemoveTerminated" -ForegroundColor Gray

