# Check deployment status on LocalStack EC2
param()

Write-Host "Checking LocalStack EC2 Deployment Status" -ForegroundColor Cyan
Write-Host ""

# 1. Check LocalStack health
Write-Host "1. LocalStack Status:" -ForegroundColor Yellow
try {
    $health = Invoke-WebRequest -Uri "http://localhost:4567/_localstack/health" -UseBasicParsing
    $healthJson = $health.Content | ConvertFrom-Json
    Write-Host "   OK LocalStack is running" -ForegroundColor Green
    $services = $healthJson.services -join ', '
    Write-Host "   Services: $services" -ForegroundColor White
}
catch {
    Write-Host "   ERROR LocalStack is not responding" -ForegroundColor Red
    Write-Host "   Start with: docker compose -f docker-compose.localstack.yml up -d localstack" -ForegroundColor Yellow
    exit 1
}

# 2. Check EC2 instances
Write-Host ""
Write-Host "2. EC2 Instances:" -ForegroundColor Yellow
try {
    $cmd = "aws --endpoint-url=http://localhost:4567 ec2 describe-instances --output json"
    $instancesJson = Invoke-Expression $cmd 2>&1
    if ($LASTEXITCODE -eq 0) {
        $instances = $instancesJson | ConvertFrom-Json
        if ($instances.Reservations -and $instances.Reservations.Count -gt 0) {
            Write-Host "   OK Found EC2 instances:" -ForegroundColor Green
            foreach ($reservation in $instances.Reservations) {
                foreach ($instance in $reservation.Instances) {
                    $name = ($instance.Tags | Where-Object { $_.Key -eq "Name" }).Value
                    Write-Host "   - Instance ID: $($instance.InstanceId)" -ForegroundColor White
                    Write-Host "     State: $($instance.State.Name)" -ForegroundColor White
                    Write-Host "     Name: $name" -ForegroundColor White
                    Write-Host "     Type: $($instance.InstanceType)" -ForegroundColor White
                }
            }
        }
        else {
            Write-Host "   WARNING No EC2 instances found" -ForegroundColor Yellow
            Write-Host "   Deploy with: .\deploy-all.ps1 (requires Terraform)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "   WARNING Could not check EC2 instances" -ForegroundColor Yellow
        Write-Host "   AWS CLI may not be configured" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "   WARNING Could not check EC2 instances" -ForegroundColor Yellow
    Write-Host "   Error: $_" -ForegroundColor Red
}

# 3. Check Docker containers
Write-Host ""
Write-Host "3. Docker Containers:" -ForegroundColor Yellow
$format = "{{.Names}}|{{.Status}}"
$allContainers = docker ps --format $format
if ($allContainers) {
    $containers = $allContainers | Where-Object { $_ -match "localstack|my-tiny-app" }
    if ($containers) {
        Write-Host "   OK Running containers:" -ForegroundColor Green
        foreach ($container in $containers) {
            $parts = $container -split "\|"
            Write-Host "   - $($parts[0])" -ForegroundColor White
            Write-Host "     Status: $($parts[1])" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "   WARNING No containers found" -ForegroundColor Yellow
    }
}
else {
    Write-Host "   WARNING No containers found" -ForegroundColor Yellow
}

# 4. Check Terraform state
Write-Host ""
Write-Host "4. Terraform State:" -ForegroundColor Yellow
if (Test-Path "terraform/localstack/.terraform") {
    $originalLocation = Get-Location
    Set-Location terraform/localstack
    try {
        $stateJson = terraform show -json 2>&1
        if ($LASTEXITCODE -eq 0) {
            $state = $stateJson | ConvertFrom-Json
            if ($state.values.root_module.resources) {
                Write-Host "   OK Terraform resources found:" -ForegroundColor Green
                foreach ($resource in $state.values.root_module.resources) {
                    Write-Host "   - $($resource.type).$($resource.name)" -ForegroundColor White
                }
            }
            else {
                Write-Host "   WARNING Terraform initialized but no resources deployed" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "   WARNING Could not read Terraform state" -ForegroundColor Yellow
    }
    Set-Location $originalLocation
}
else {
    Write-Host "   WARNING Terraform not initialized" -ForegroundColor Yellow
    Write-Host "   Initialize with: cd terraform/localstack; terraform init" -ForegroundColor White
}

# 5. Check VPC and Networking
Write-Host ""
Write-Host "5. VPC and Networking:" -ForegroundColor Yellow
try {
    $cmd = "aws --endpoint-url=http://localhost:4567 ec2 describe-vpcs --output json"
    $vpcsJson = Invoke-Expression $cmd 2>&1
    if ($LASTEXITCODE -eq 0) {
        $vpcs = $vpcsJson | ConvertFrom-Json
        if ($vpcs.Vpcs -and $vpcs.Vpcs.Count -gt 0) {
            Write-Host "   OK VPCs found:" -ForegroundColor Green
            foreach ($vpc in $vpcs.Vpcs) {
                Write-Host "   - VPC: $($vpc.VpcId) ($($vpc.CidrBlock))" -ForegroundColor White
            }
        }
        else {
            Write-Host "   WARNING No VPCs found" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Host "   WARNING Could not check VPCs" -ForegroundColor Yellow
}

# 6. Test application endpoints
Write-Host ""
Write-Host "6. Application Endpoints:" -ForegroundColor Yellow
try {
    $api = Invoke-WebRequest -Uri "http://localhost:3000/api/items" -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
    if ($api.StatusCode -eq 200) {
        Write-Host "   OK API (port 3000) is responding" -ForegroundColor Green
    }
}
catch {
    Write-Host "   WARNING API (port 3000) is not responding" -ForegroundColor Yellow
}

try {
    $consumer = Invoke-WebRequest -Uri "http://localhost:3001/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
    if ($consumer.StatusCode -eq 200) {
        Write-Host "   OK Consumer (port 3001) is responding" -ForegroundColor Green
    }
}
catch {
    Write-Host "   WARNING Consumer (port 3001) is not responding" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  - LocalStack: Running on port 4567" -ForegroundColor White
Write-Host "  - To deploy to EC2: Install Terraform and run .\deploy-all.ps1" -ForegroundColor White
Write-Host "  - To run as containers: Run .\deploy-simple.ps1" -ForegroundColor White
Write-Host ""

