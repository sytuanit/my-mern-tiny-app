# Deploy my-tiny-app, my-tiny-app-consumer, and my-tiny-app-ui to Minikube
# Chạy: .\deploy-minikube.ps1

$ErrorActionPreference = "Stop"

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🚀 Deploying to Minikube" -ForegroundColor Cyan
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

# Step 2: Set Docker environment to use Minikube's Docker daemon
Write-Host "Step 2: Configuring Docker to use Minikube's daemon..." -ForegroundColor Yellow
& minikube docker-env | Invoke-Expression
Write-Host "✅ Docker configured for Minikube" -ForegroundColor Green
Write-Host ""

# Step 3: Build Docker images
Write-Host "Step 3: Building Docker images..." -ForegroundColor Yellow

Write-Host "  Building my-tiny-app..." -ForegroundColor White
docker build -t my-tiny-app:latest ./my-tiny-app
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build my-tiny-app" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ my-tiny-app built" -ForegroundColor Green

Write-Host "  Building my-tiny-app-consumer..." -ForegroundColor White
docker build -t my-tiny-app-consumer:latest ./my-tiny-app-consumer 2>&1 | Out-Null
$buildSuccess = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String "my-tiny-app-consumer:latest"
if (-not $buildSuccess) {
    Write-Host "❌ Failed to build my-tiny-app-consumer" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ my-tiny-app-consumer built" -ForegroundColor Green

Write-Host "  Building my-tiny-app-ui..." -ForegroundColor White
docker build -t my-tiny-app-ui:latest ./my-tiny-app-ui 2>&1 | Out-Null
$buildSuccess = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String "my-tiny-app-ui:latest"
if (-not $buildSuccess) {
    Write-Host "❌ Failed to build my-tiny-app-ui" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ my-tiny-app-ui built" -ForegroundColor Green
Write-Host ""

# Step 4: Enable Ingress addon (if not already enabled)
Write-Host "Step 4: Enabling Ingress addon..." -ForegroundColor Yellow
minikube addons enable ingress 2>&1 | Out-Null
Write-Host "✅ Ingress enabled" -ForegroundColor Green
Write-Host ""

# Step 5: Apply Kubernetes manifests
Write-Host "Step 5: Deploying to Kubernetes..." -ForegroundColor Yellow

$manifests = @(
    "k8s/00-namespace.yaml",
    "k8s/01-configmap.yaml",
    "k8s/02-mongodb.yaml",
    "k8s/03-zookeeper.yaml",
    "k8s/04-kafka.yaml",
    "k8s/05-app.yaml",
    "k8s/06-consumer.yaml",
    "k8s/07-ui.yaml",
    "k8s/08-ingress.yaml"
)

foreach ($manifest in $manifests) {
    if (Test-Path $manifest) {
        Write-Host "  Applying $manifest..." -ForegroundColor White
        kubectl apply -f $manifest
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Failed to apply $manifest" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "⚠️  Manifest not found: $manifest" -ForegroundColor Yellow
    }
}

Write-Host "✅ All manifests applied" -ForegroundColor Green
Write-Host ""

# Step 6: Wait for deployments to be ready
Write-Host "Step 6: Waiting for deployments to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=300s deployment/my-tiny-app -n my-tiny-app 2>&1 | Out-Null
kubectl wait --for=condition=available --timeout=300s deployment/my-tiny-app-consumer -n my-tiny-app 2>&1 | Out-Null
kubectl wait --for=condition=available --timeout=300s deployment/my-tiny-app-ui -n my-tiny-app 2>&1 | Out-Null
Write-Host "✅ Deployments ready" -ForegroundColor Green
Write-Host ""

# Step 7: Get service URLs
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

Write-Host "To access via Ingress (if enabled):" -ForegroundColor Yellow
Write-Host "  Add to /etc/hosts or C:\Windows\System32\drivers\etc\hosts:" -ForegroundColor White
Write-Host "    $minikubeIP my-tiny-app.local" -ForegroundColor Gray
Write-Host "  Then access: http://my-tiny-app.local" -ForegroundColor White
Write-Host ""

Write-Host "Useful commands:" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n my-tiny-app" -ForegroundColor Gray
Write-Host "  kubectl get services -n my-tiny-app" -ForegroundColor Gray
Write-Host "  kubectl logs -f deployment/my-tiny-app -n my-tiny-app" -ForegroundColor Gray
Write-Host "  minikube service my-tiny-app-ui-service -n my-tiny-app" -ForegroundColor Gray
Write-Host ""

