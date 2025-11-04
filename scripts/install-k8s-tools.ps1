# Install Kubernetes tools (kubectl, minikube) using Chocolatey
# PHẢI chạy PowerShell as Administrator!
# Chạy: .\install-k8s-tools.ps1

$ErrorActionPreference = "Stop"

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "☸️  Installing Kubernetes Tools" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "  1. Right-click PowerShell" -ForegroundColor White
    Write-Host "  2. Select 'Run as Administrator'" -ForegroundColor White
    Write-Host "  3. Run this script again" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "✅ Running as Administrator" -ForegroundColor Green
Write-Host ""

# Check if Chocolatey is installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Chocolatey is not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Chocolatey first:" -ForegroundColor Yellow
    Write-Host "  .\install-chocolatey.ps1" -ForegroundColor White
    Write-Host ""
    exit 1
}

$chocoVersion = choco --version
Write-Host "✅ Chocolatey version: $chocoVersion" -ForegroundColor Green
Write-Host ""

# Fix lock files first
Write-Host "Checking for lock files..." -ForegroundColor Yellow
$chocoLib = "C:\ProgramData\chocolatey\lib"
$lockFiles = Get-ChildItem -Path $chocoLib -Filter "*" -Directory -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -match '^[a-f0-9]{40}$' }

if ($lockFiles) {
    Write-Host "⚠️  Found lock files, removing..." -ForegroundColor Yellow
    foreach ($lock in $lockFiles) {
        try {
            Remove-Item -Path $lock.FullName -Recurse -Force -ErrorAction Stop
            Write-Host "  ✅ Removed: $($lock.Name)" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️  Could not remove: $($lock.Name)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "✅ No lock files found" -ForegroundColor Green
}

Write-Host ""

# Tools to install
$tools = @(
    @{ Name = "kubernetes-cli"; DisplayName = "kubectl" },
    @{ Name = "minikube"; DisplayName = "Minikube" }
)

foreach ($tool in $tools) {
    Write-Host "───────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "Installing $($tool.DisplayName)..." -ForegroundColor Yellow
    Write-Host "───────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    # Check if already installed
    $installed = choco list --local-only $tool.Name 2>$null | Select-String -Pattern "^$($tool.Name)\s"
    
    if ($installed) {
        Write-Host "✅ $($tool.DisplayName) is already installed" -ForegroundColor Green
        $version = choco list --local-only $tool.Name 2>$null | Select-String -Pattern "^\S+\s+(\S+)" | ForEach-Object { $_.Matches.Groups[1].Value }
        Write-Host "   Version: $version" -ForegroundColor Gray
        Write-Host ""
        continue
    }
    
    # Install
    try {
        choco install $tool.Name -y --no-progress
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $($tool.DisplayName) installed successfully!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Installation may have issues (exit code: $LASTEXITCODE)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Failed to install $($tool.DisplayName): $_" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Verify installations
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Installation Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$kubectlInstalled = Get-Command kubectl -ErrorAction SilentlyContinue
$minikubeInstalled = Get-Command minikube -ErrorAction SilentlyContinue

if ($kubectlInstalled) {
    $kubectlVersion = kubectl version --client --short 2>$null
    Write-Host "✅ kubectl:" -ForegroundColor Green
    Write-Host "   $kubectlVersion" -ForegroundColor Gray
} else {
    Write-Host "❌ kubectl: Not found (may need to restart PowerShell)" -ForegroundColor Red
}

Write-Host ""

if ($minikubeInstalled) {
    $minikubeVersion = minikube version --short 2>$null
    Write-Host "✅ minikube:" -ForegroundColor Green
    Write-Host "   $minikubeVersion" -ForegroundColor Gray
} else {
    Write-Host "❌ minikube: Not found (may need to restart PowerShell)" -ForegroundColor Red
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📝 Next Steps" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($kubectlInstalled -and $minikubeInstalled) {
    Write-Host "1. Start Minikube:" -ForegroundColor Yellow
    Write-Host "   minikube start" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Verify Minikube is running:" -ForegroundColor Yellow
    Write-Host "   kubectl get nodes" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Deploy your applications:" -ForegroundColor Yellow
    Write-Host "   .\deploy-minikube.ps1" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "⚠️  If tools are not found, please:" -ForegroundColor Yellow
    Write-Host "   1. Restart PowerShell (close and reopen)" -ForegroundColor White
    Write-Host "   2. Or run: refreshenv" -ForegroundColor White
    Write-Host "   3. Verify: kubectl version --client" -ForegroundColor White
    Write-Host ""
}

