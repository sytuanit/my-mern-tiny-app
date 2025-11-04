# Fix Chocolatey lock file issues and check admin rights
# Chay PowerShell as Administrator, sau do chay: .\fix-choco-lock.ps1

$ErrorActionPreference = "Stop"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Fix Chocolatey Lock File Issues" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[ERROR] This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "  1. Right-click PowerShell" -ForegroundColor White
    Write-Host "  2. Select 'Run as Administrator'" -ForegroundColor White
    Write-Host "  3. Run this script again" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "[OK] Running as Administrator" -ForegroundColor Green
Write-Host ""

# Chocolatey directories
$chocoLib = "C:\ProgramData\chocolatey\lib"
$chocoDir = "C:\ProgramData\chocolatey\.chocolatey"

Write-Host "Checking for lock files..." -ForegroundColor Yellow

# Check for lock files
$lockFiles = Get-ChildItem -Path $chocoLib -Filter "*" -Directory -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -match '^[a-f0-9]{40}$' }

if ($lockFiles) {
    Write-Host ""
    Write-Host "[WARNING] Found potential lock files:" -ForegroundColor Yellow
    foreach ($lock in $lockFiles) {
        Write-Host "  - $($lock.FullName)" -ForegroundColor Gray
    }
    Write-Host ""
    
    $response = Read-Host "Do you want to remove these lock files? (Y/N)"
    if ($response -eq 'Y' -or $response -eq 'y') {
        foreach ($lock in $lockFiles) {
            try {
                Remove-Item -Path $lock.FullName -Recurse -Force -ErrorAction Stop
                Write-Host "  [OK] Removed: $($lock.Name)" -ForegroundColor Green
            } catch {
                Write-Host "  [ERROR] Failed to remove: $($lock.Name) - $_" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "[OK] No lock files found" -ForegroundColor Green
}

Write-Host ""
Write-Host "Checking Chocolatey directory permissions..." -ForegroundColor Yellow

# Ensure .chocolatey directory exists and has correct permissions
if (-not (Test-Path $chocoDir)) {
    try {
        New-Item -ItemType Directory -Path $chocoDir -Force | Out-Null
        Write-Host "[OK] Created directory: $chocoDir" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to create directory: $_" -ForegroundColor Red
    }
} else {
    Write-Host "[OK] Directory exists: $chocoDir" -ForegroundColor Green
}

# Fix permissions
try {
    $acl = Get-Acl $chocoDir
    $permission = "BUILTIN\Users", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($accessRule)
    Set-Acl $chocoDir $acl
    Write-Host "[OK] Fixed permissions on $chocoDir" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Could not fix permissions (may already be correct): $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "[OK] Fix completed!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Now you can install packages:" -ForegroundColor Yellow
Write-Host "  choco install kubernetes-cli -y" -ForegroundColor White
Write-Host "  choco install minikube -y" -ForegroundColor White
Write-Host ""

