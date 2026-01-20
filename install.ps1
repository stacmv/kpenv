# kpenv installer for Windows
# Installs kpenv using Scoop package manager
# Requires: Scoop (https://scoop.sh)

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Success { param($msg) Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Error { param($msg) Write-Host "✗ $msg" -ForegroundColor Red }
function Write-Warning { param($msg) Write-Host "⚠ $msg" -ForegroundColor Yellow }
function Write-Info { param($msg) Write-Host "  $msg" -ForegroundColor Cyan }

Write-Host "🔧 Installing kpenv (KeePass Environment Manager)..." -ForegroundColor Cyan
Write-Host ""

# 1. Check if Scoop is installed
Write-Host "Checking prerequisites..."
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Error "Scoop package manager not found"
    Write-Host ""
    Write-Info "Scoop is required for managing dependencies on Windows."
    Write-Info "Please install Scoop first: https://scoop.sh"
    Write-Host ""
    Write-Info "Quick install (run in PowerShell):"
    Write-Host '  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser' -ForegroundColor Gray
    Write-Host '  Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression' -ForegroundColor Gray
    Write-Host ""
    exit 1
}
Write-Success "Scoop found"

# 2. Check PHP
if (-not (Get-Command php -ErrorAction SilentlyContinue)) {
    Write-Warning "PHP not found"
    Write-Info "PHP 8.2+ is required for kpenv"
    $response = Read-Host "Install PHP via Scoop? [Y/n]"
    if ($response -eq '' -or $response -match '^[Yy]$') {
        Write-Host "Installing PHP..."
        scoop install php
        if (-not $?) {
            Write-Error "Failed to install PHP"
            exit 1
        }
        Write-Success "PHP installed"
    } else {
        Write-Error "PHP is required. Installation cancelled."
        exit 1
    }
} else {
    # Check PHP version
    $phpVersion = php -r "echo PHP_VERSION;"
    $requiredVersion = [version]"8.2.0"
    $currentVersion = [version]$phpVersion

    if ($currentVersion -lt $requiredVersion) {
        Write-Error "PHP 8.2+ required (found $phpVersion)"
        Write-Info "Please upgrade PHP:"
        Write-Info "  scoop update php"
        exit 1
    }

    Write-Success "PHP $phpVersion found"
}

# 3. Check KeePassXC CLI (warn but don't fail)
if (-not (Get-Command keepassxc-cli -ErrorAction SilentlyContinue)) {
    Write-Warning "keepassxc-cli not found"
    Write-Info "KeePassXC is needed for backup/restore features"
    $response = Read-Host "Install KeePassXC via Scoop? [Y/n]"
    if ($response -eq '' -or $response -match '^[Yy]$') {
        Write-Host "Installing KeePassXC..."
        # KeePassXC is in extras bucket
        scoop bucket add extras 2>$null
        scoop install keepassxc
        if (-not $?) {
            Write-Warning "Failed to install KeePassXC"
            Write-Info "You can install it manually later: scoop install keepassxc"
        } else {
            Write-Success "KeePassXC installed"
        }
    } else {
        Write-Warning "Continuing without KeePassXC"
        Write-Info "Install later with: scoop install keepassxc"
    }
} else {
    Write-Success "keepassxc-cli found"
}

# 4. Check for Unix-like shell (optional but recommended)
if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Warning "Unix-like shell not found"
    Write-Info "kpenv works best with Unix-like shells (Git Bash, MSYS2, WSL, Cmder)"
    Write-Info "Cmder provides a portable console emulator with bash support"
    $response = Read-Host "Install Cmder via Scoop? [y/N]"
    if ($response -match '^[Yy]$') {
        Write-Host "Installing Cmder..."
        scoop bucket add extras 2>$null
        scoop install cmder
        if (-not $?) {
            Write-Warning "Failed to install Cmder"
            Write-Info "You can install it manually later: scoop install cmder"
        } else {
            Write-Success "Cmder installed"
            Write-Info "Launch Cmder to use kpenv in a Unix-like environment"
        }
    } else {
        Write-Info "You can install Git Bash, MSYS2, WSL, or Cmder for better compatibility"
        Write-Info "  Git Bash: scoop install git"
        Write-Info "  Cmder: scoop install cmder"
    }
}

Write-Host ""

# 5. Determine installation directory
# Install to user's scoop apps directory for consistency
$installDir = "$env:USERPROFILE\scoop\shims"
if (Test-Path "$env:USERPROFILE\scoop") {
    $kpenvDir = "$env:USERPROFILE\scoop\apps\kpenv\current"
} else {
    # Fallback to %USERPROFILE%\bin
    $installDir = "$env:USERPROFILE\bin"
    $kpenvDir = $installDir
    if (-not (Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }
}

# 6. Install kpenv executable
Write-Host "Installing kpenv..."

if (Test-Path ".\kpenv") {
    # Local installation
    Write-Host "Installing from local file..."

    # Create app directory structure for scoop compatibility
    if (Test-Path "$env:USERPROFILE\scoop") {
        $kpenvAppDir = "$env:USERPROFILE\scoop\apps\kpenv\current"
        if (-not (Test-Path $kpenvAppDir)) {
            New-Item -ItemType Directory -Path $kpenvAppDir -Force | Out-Null
        }
        Copy-Item ".\kpenv" "$kpenvAppDir\kpenv" -Force

        # Create shim in scoop shims directory
        $shimContent = @"
@echo off
php "$kpenvAppDir\kpenv" %*
"@
        $shimContent | Out-File -FilePath "$env:USERPROFILE\scoop\shims\kpenv.cmd" -Encoding ASCII -Force
        $installedPath = "$env:USERPROFILE\scoop\shims\kpenv.cmd"
    } else {
        Copy-Item ".\kpenv" "$installDir\kpenv" -Force

        # Create batch wrapper
        $wrapperContent = @"
@echo off
php "$installDir\kpenv" %*
"@
        $wrapperContent | Out-File -FilePath "$installDir\kpenv.cmd" -Encoding ASCII -Force
        $installedPath = "$installDir\kpenv.cmd"
    }
} else {
    Write-Error "kpenv file not found in current directory"
    Write-Info "Please run this installer from the kpenv repository directory"
    exit 1
}

Write-Success "Installed to $installedPath"

# 7. Add to PATH if needed
if ($installDir -ne "$env:USERPROFILE\scoop\shims") {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$installDir*") {
        Write-Host ""
        Write-Warning "Installation directory is not in PATH"
        $response = Read-Host "Add $installDir to PATH? [Y/n]"
        if ($response -eq '' -or $response -match '^[Yy]$') {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installDir", "User")
            Write-Success "Added $installDir to PATH"
            Write-Info "Please restart your terminal for PATH changes to take effect"
        } else {
            Write-Warning "Skipped PATH modification"
            Write-Info "Add manually: `$env:Path += ';$installDir'"
        }
    }
}

# 8. Create config directory
Write-Host ""
Write-Host "Setting up configuration..."
$configDir = "$env:USERPROFILE\.kpenv"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

# 9. Create default config if not exists
$configFile = "$configDir\config.json"
if (-not (Test-Path $configFile)) {
    # Use Windows-style paths
    $defaultConfig = @{
        base_dev_folder = "$env:USERPROFILE\dev"
        keepass_db = "$env:USERPROFILE\Documents\work-secrets.kdbx"
        default_env = "development"
        example_files = @(
            ".env.example",
            "env.example",
            ".env.dist",
            "example.env"
        )
        auto_gitignore = $true
    } | ConvertTo-Json -Depth 10

    $defaultConfig | Out-File -FilePath $configFile -Encoding UTF8 -Force
    Write-Success "Created default config at $configFile"
    Write-Info "You can edit this file to customize paths"
} else {
    Write-Success "Config already exists at $configFile"
}

# 10. Shell completions note
Write-Host ""
Write-Info "Note: PowerShell completions are not yet implemented"
Write-Info "Shell completions are available for Bash/Zsh on Unix systems"

Write-Host ""
Write-Host "✅ Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Quick start:"
Write-Info "cd your-project"
Write-Info "kpenv init          # Initialize project"
Write-Info "kpenv --help        # Show all commands"
Write-Host ""
Write-Host "Configuration:"
Write-Info "$configFile - User settings"
Write-Host ""

# Check if kpenv is immediately available
$kpenvAvailable = Get-Command kpenv -ErrorAction SilentlyContinue
if (-not $kpenvAvailable) {
    Write-Warning "Please restart your terminal to use kpenv"
}
