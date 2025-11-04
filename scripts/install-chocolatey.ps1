# Install Chocolatey on Windows
# Chạy PowerShell as Administrator, sau đó chạy: .\install-chocolatey.ps1
# Hoặc chạy trực tiếp từ URL: Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

$ErrorActionPreference = "Stop"

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🍫 Installing Chocolatey" -ForegroundColor Cyan
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
    Write-Host "Or run this command directly:" -ForegroundColor Yellow
    Write-Host "  Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" -ForegroundColor Gray
    exit 1
}

Write-Host "✅ Running as Administrator" -ForegroundColor Green
Write-Host ""

# Check if Chocolatey is already installed
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "✅ Chocolatey is already installed!" -ForegroundColor Green
    $chocoVersion = choco --version
    Write-Host "   Version: $chocoVersion" -ForegroundColor White
    Write-Host ""
    Write-Host "To install Minikube:" -ForegroundColor Yellow
    Write-Host "  choco install minikube -y" -ForegroundColor White
    exit 0
}

Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
Write-Host ""

# Set execution policy for current process
Set-ExecutionPolicy Bypass -Scope Process -Force

# Set TLS 1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

# Install Chocolatey
try {
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    if ($LASTEXITCODE -eq 0 -or (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "✅ Chocolatey installed successfully!" -ForegroundColor Green
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Write-Host ""
        Write-Host "Please restart your PowerShell session or run:" -ForegroundColor Yellow
        Write-Host "  refreshenv" -ForegroundColor White
        Write-Host ""
        Write-Host "Then install Minikube:" -ForegroundColor Yellow
        Write-Host "  choco install minikube -y" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "❌ Chocolatey installation may have failed" -ForegroundColor Red
        Write-Host "   Please check the error messages above" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error installing Chocolatey: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "You can try installing manually:" -ForegroundColor Yellow
    Write-Host "  Set-ExecutionPolicy Bypass -Scope Process -Force" -ForegroundColor White
    Write-Host "  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072" -ForegroundColor White
    Write-Host "  iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" -ForegroundColor White
    exit 1
}

