# kpenv uninstaller for Windows
# Removes kpenv from system

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Success {
    param($msg)
    Write-Host "[OK] $msg" -ForegroundColor Green
}
function Write-CustomError {
    param($msg)
    Write-Host "[ERROR] $msg" -ForegroundColor Red
}
function Write-CustomWarning {
    param($msg)
    Write-Host "[WARN] $msg" -ForegroundColor Yellow
}
function Write-Info {
    param($msg)
    Write-Host "  $msg" -ForegroundColor Cyan
}

Write-Host "Uninstalling kpenv..." -ForegroundColor Cyan
Write-Host ""

$removed = $false

# 1. Remove from scoop apps directory
if (Test-Path "$env:USERPROFILE\scoop\apps\kpenv") {
    Write-Host "Removing kpenv from Scoop apps..."
    Remove-Item -Path "$env:USERPROFILE\scoop\apps\kpenv" -Recurse -Force
    Write-Success "Removed $env:USERPROFILE\scoop\apps\kpenv"
    $removed = $true
}

# 2. Remove shim
if (Test-Path "$env:USERPROFILE\scoop\shims\kpenv.cmd") {
    Write-Host "Removing kpenv shim..."
    Remove-Item -Path "$env:USERPROFILE\scoop\shims\kpenv.cmd" -Force
    Write-Success "Removed $env:USERPROFILE\scoop\shims\kpenv.cmd"
    $removed = $true
}

# 3. Remove from fallback location
if (Test-Path "$env:USERPROFILE\bin\kpenv") {
    Write-Host "Removing kpenv from fallback location..."
    Remove-Item -Path "$env:USERPROFILE\bin\kpenv" -Force
    Write-Success "Removed $env:USERPROFILE\bin\kpenv"
    $removed = $true
}

if (Test-Path "$env:USERPROFILE\bin\kpenv.cmd") {
    Remove-Item -Path "$env:USERPROFILE\bin\kpenv.cmd" -Force
    Write-Success "Removed $env:USERPROFILE\bin\kpenv.cmd"
    $removed = $true
}

if (-not $removed) {
    Write-CustomWarning "kpenv installation not found"
}

Write-Host ""

# 4. Ask about config
$configDir = "$env:USERPROFILE\.kpenv"
if (Test-Path $configDir) {
    Write-Host "Configuration directory exists: $configDir"
    Write-Info "This contains your user settings."
    Write-Host ""
    $response = Read-Host "Remove config directory? [y/N]"
    if ($response -match '^[Yy]$') {
        Remove-Item -Path $configDir -Recurse -Force
        Write-Success "Removed $configDir"
    } else {
        Write-CustomWarning "Keeping $configDir"
    }
} else {
    Write-Info "No config directory found"
}

Write-Host ""
Write-Host "[COMPLETE] Uninstall complete" -ForegroundColor Green
Write-Host ""
Write-Info "Note: Project-specific .kpenv.json files in your projects were not removed."
Write-Info "You can manually delete them if needed."
Write-Host ""
