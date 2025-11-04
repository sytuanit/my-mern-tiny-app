# Deploy to Minikube using Terraform
# Chạy: .\deploy-minikube-terraform.ps1

$ErrorActionPreference = "Stop"

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🚀 Deploying to Minikube using Terraform" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if Minikube is running
Write-Host "Step 1: Checking Minikube status..." -ForegroundColor Yellow
try {
    $minikubeStatus = minikube status --format json 2>&1 | ConvertFrom-Json
    if ($minikubeStatus.Host -ne "Running") {
        Write-Host "❌ Minikube is not running. Starting Minikube..." -ForegroundColor Red
        minikube start
    } else {
        Write-Host "✅ Minikube is running" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Minikube is not installed or not in PATH" -ForegroundColor Red
    Write-Host "   Install from: https://minikube.sigs.k8s.io/docs/start/" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Step 2: Check if Terraform is available
Write-Host "Step 2: Checking Terraform..." -ForegroundColor Yellow
try {
    $terraformVersion = terraform version
    Write-Host "✅ Terraform is available" -ForegroundColor Green
} catch {
    Write-Host "❌ Terraform is not installed" -ForegroundColor Red
    Write-Host "   Install from: https://www.terraform.io/downloads" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Step 3: Set Docker environment to use Minikube's Docker daemon
Write-Host "Step 3: Configuring Docker to use Minikube's daemon..." -ForegroundColor Yellow
& minikube docker-env | Invoke-Expression
Write-Host "✅ Docker configured for Minikube" -ForegroundColor Green
Write-Host ""

# Step 4: Build Docker images
Write-Host "Step 4: Building Docker images..." -ForegroundColor Yellow

Write-Host "  Building my-tiny-app..." -ForegroundColor White
docker build -t localhost/my-tiny-app:latest ./my-tiny-app
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build my-tiny-app" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ my-tiny-app built" -ForegroundColor Green

Write-Host "  Building my-tiny-app-consumer..." -ForegroundColor White
docker build -t localhost/my-tiny-app-consumer:latest ./my-tiny-app-consumer 2>&1 | Out-Null
$buildSuccess = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String "localhost/my-tiny-app-consumer:latest"
if (-not $buildSuccess) {
    Write-Host "❌ Failed to build my-tiny-app-consumer" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ my-tiny-app-consumer built" -ForegroundColor Green

Write-Host "  Building my-tiny-app-ui..." -ForegroundColor White
docker build -t localhost/my-tiny-app-ui:latest ./my-tiny-app-ui 2>&1 | Out-Null
$buildSuccess = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String "localhost/my-tiny-app-ui:latest"
if (-not $buildSuccess) {
    Write-Host "❌ Failed to build my-tiny-app-ui" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ my-tiny-app-ui built" -ForegroundColor Green
Write-Host ""

# Step 5: Initialize Terraform
Write-Host "Step 5: Initializing Terraform..." -ForegroundColor Yellow
Set-Location terraform/kubernetes
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform initialization failed" -ForegroundColor Red
    Set-Location ../..
    exit 1
}
Write-Host "✅ Terraform initialized" -ForegroundColor Green
Write-Host ""

# Step 6: Plan Terraform
Write-Host "Step 6: Planning Terraform deployment..." -ForegroundColor Yellow
terraform plan `
  -var="docker_registry=localhost" `
  -var="image_tag=latest" `
  -var="image_pull_policy=Never" `
  -var="kube_context=minikube"
Write-Host ""

# Step 7: Apply Terraform
Write-Host "Step 7: Applying Terraform configuration..." -ForegroundColor Yellow
$confirm = Read-Host "Do you want to apply? (yes/no)"
if ($confirm -eq "yes" -or $confirm -eq "y") {
    terraform apply -auto-approve `
      -var="docker_registry=localhost" `
      -var="image_tag=latest" `
      -var="image_pull_policy=Never" `
      -var="kube_context=minikube"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Terraform apply failed" -ForegroundColor Red
        Set-Location ../..
        exit 1
    }
} else {
    Write-Host "⚠️  Deployment cancelled" -ForegroundColor Yellow
    Set-Location ../..
    exit 0
}
Write-Host ""

# Step 8: Get outputs
Write-Host "Step 8: Getting deployment outputs..." -ForegroundColor Yellow
terraform output
Write-Host ""

# Step 9: Wait for deployments
Write-Host "Step 9: Waiting for deployments to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=300s deployment/my-tiny-app -n my-tiny-app 2>&1 | Out-Null
kubectl wait --for=condition=available --timeout=300s deployment/my-tiny-app-consumer -n my-tiny-app 2>&1 | Out-Null
kubectl wait --for=condition=available --timeout=300s deployment/my-tiny-app-ui -n my-tiny-app 2>&1 | Out-Null
Write-Host "✅ Deployments ready" -ForegroundColor Green
Write-Host ""

Set-Location ../..

# Step 10: Summary
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

$minikubeIP = minikube ip
Write-Host "Minikube IP: $minikubeIP" -ForegroundColor Cyan
Write-Host ""

Write-Host "Access Points:" -ForegroundColor Yellow
Write-Host "  UI (NodePort):     http://$minikubeIP:30002" -ForegroundColor White
Write-Host "  API (Internal):    http://my-tiny-app-service:3000" -ForegroundColor White
Write-Host "  Consumer:         http://my-tiny-app-consumer-service:3001" -ForegroundColor White
Write-Host ""

Write-Host "Useful commands:" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n my-tiny-app" -ForegroundColor Gray
Write-Host "  kubectl get services -n my-tiny-app" -ForegroundColor Gray
Write-Host "  kubectl logs -f deployment/my-tiny-app -n my-tiny-app" -ForegroundColor Gray
Write-Host "  terraform destroy -var='docker_registry=localhost' -var='image_tag=latest' -var='image_pull_policy=Never' -var='kube_context=minikube'" -ForegroundColor Gray
Write-Host ""

