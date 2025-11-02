# Find Terraform installation
Write-Host "Searching for Terraform..." -ForegroundColor Cyan

# Common installation locations
$searchPaths = @(
    "C:\Program Files\Terraform",
    "C:\Program Files (x86)\Terraform",
    "$env:LOCALAPPDATA\Programs\Terraform",
    "$env:USERPROFILE\terraform",
    "$env:USERPROFILE\.terraform",
    "$env:USERPROFILE\AppData\Local\Programs\Terraform"
)

$found = $false
foreach ($path in $searchPaths) {
    if (Test-Path "$path\terraform.exe") {
        Write-Host "Found Terraform at: $path\terraform.exe" -ForegroundColor Green
        Write-Host ""
        Write-Host "To add to PATH for current session, run:" -ForegroundColor Yellow
        $addPathCmd = '$env:Path += ";' + $path + '"'
        Write-Host "  $addPathCmd" -ForegroundColor White
        Write-Host ""
        Write-Host "Or to test directly:" -ForegroundColor Yellow
        Write-Host "  & `"$path\terraform.exe`" --version" -ForegroundColor White
        $found = $true
        break
    }
}

if (-not $found) {
    Write-Host "Terraform not found in common locations." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Checking winget installation..." -ForegroundColor Cyan
    try {
        $winget = winget list Hashicorp.Terraform 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Terraform is installed via winget" -ForegroundColor Green
            Write-Host "You may need to restart PowerShell for PATH to update." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Try finding in WinGet packages folder:" -ForegroundColor Yellow
            $wingetPath = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages"
            if (Test-Path $wingetPath) {
                $terraformDirs = Get-ChildItem -Path $wingetPath -Filter "*Terraform*" -Directory -ErrorAction SilentlyContinue
                foreach ($dir in $terraformDirs) {
                    $tfExe = Join-Path $dir.FullName "terraform.exe"
                    if (Test-Path $tfExe) {
                        Write-Host "  Found: $tfExe" -ForegroundColor Green
                        Write-Host "  Run: & `"$tfExe`" --version" -ForegroundColor White
                    }
                }
            }
        }
        else {
            Write-Host "Terraform may not be installed yet." -ForegroundColor Red
            Write-Host "Install with: winget install Hashicorp.Terraform" -ForegroundColor White
        }
    }
    catch {
        Write-Host "Could not check winget" -ForegroundColor Yellow
    }
}
