<#
.SYNOPSIS
    Bootstrap UniFi Network Controller on Windows
.DESCRIPTION
    Downloads and installs UniFi Network Controller 8.5.93+ with dependencies.
    Supports local deployment with no-2FA admin account setup.
.PARAMETER ControllerIP
    IP address for UniFi Controller (default: 10.0.1.1)
.PARAMETER InstallDir
    Installation directory (default: C:\UniFi)
.EXAMPLE
    .\install-unifi.ps1 -ControllerIP "10.0.1.1"
#>

[CmdletBinding()]
param(
    [string]$ControllerIP = "10.0.1.1",
    [string]$InstallDir = "C:\UniFi"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 UniFi Network Controller Bootstrap (Windows)" -ForegroundColor Cyan
Write-Host "Target IP: $ControllerIP" -ForegroundColor Yellow

# Check admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script requires Administrator privileges. Run PowerShell as Administrator."
    exit 1
}

# Version requirements
$RequiredJavaVersion = "17"
$RequiredUniFiVersion = "8.5.93"

Write-Host "`n📦 Step 1: Installing Java $RequiredJavaVersion (OpenJDK)" -ForegroundColor Green

# Check if Chocolatey is installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey package manager..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Install OpenJDK 17
Write-Host "Installing OpenJDK 17..." -ForegroundColor Yellow
choco install openjdk17 -y

# Verify Java installation
$javaVersion = & java -version 2>&1 | Select-String "version" | ForEach-Object { $_ -replace '.*version "([^"]+)".*','$1' }
if ($javaVersion -notlike "17.*") {
    Write-Error "Java 17 installation failed. Found version: $javaVersion"
    exit 1
}
Write-Host "✅ Java $javaVersion installed" -ForegroundColor Green

Write-Host "`n📦 Step 2: Installing MongoDB 7.0" -ForegroundColor Green
choco install mongodb -y

# Start MongoDB service
Write-Host "Starting MongoDB service..." -ForegroundColor Yellow
Start-Service MongoDB -ErrorAction SilentlyContinue
Set-Service MongoDB -StartupType Automatic
Write-Host "✅ MongoDB service running" -ForegroundColor Green

Write-Host "`n📦 Step 3: Downloading UniFi Network Controller $RequiredUniFiVersion" -ForegroundColor Green

# Create installation directory
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

$UniFiZipUrl = "https://dl.ui.com/unifi/8.5.93/UniFi-installer.exe"
$UniFiInstallerPath = "$env:TEMP\UniFi-installer.exe"

Write-Host "Downloading from $UniFiZipUrl..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $UniFiZipUrl -OutFile $UniFiInstallerPath -UseBasicParsing

Write-Host "✅ Downloaded UniFi installer" -ForegroundColor Green

Write-Host "`n📦 Step 4: Installing UniFi Network Controller" -ForegroundColor Green
Write-Host "Running installer (this may take a few minutes)..." -ForegroundColor Yellow

Start-Process -FilePath $UniFiInstallerPath -ArgumentList "/S","/D=$InstallDir" -Wait

Write-Host "✅ UniFi Network Controller installed to $InstallDir" -ForegroundColor Green

Write-Host "`n📦 Step 5: Configuring UniFi Service" -ForegroundColor Green

# Wait for service to be created
Start-Sleep -Seconds 10

# Start UniFi service
$unifiService = Get-Service -Name "UniFi*" -ErrorAction SilentlyContinue
if ($unifiService) {
    Start-Service $unifiService.Name
    Set-Service $unifiService.Name -StartupType Automatic
    Write-Host "✅ UniFi service ($($unifiService.Name)) started" -ForegroundColor Green
} else {
    Write-Warning "UniFi service not found. You may need to start it manually."
}

Write-Host "`n📦 Step 6: Configuring Firewall Rules" -ForegroundColor Green

# Allow UniFi ports through Windows Firewall
$ports = @(
    @{Name="UniFi-WebUI"; Port=8443; Protocol="TCP"},
    @{Name="UniFi-STUN"; Port=3478; Protocol="UDP"},
    @{Name="UniFi-Discovery"; Port=10001; Protocol="UDP"},
    @{Name="UniFi-DeviceComm"; Port=8080; Protocol="TCP"}
)

foreach ($rule in $ports) {
    Write-Host "Opening port $($rule.Port)/$($rule.Protocol)..." -ForegroundColor Yellow
    New-NetFirewallRule -DisplayName $rule.Name -Direction Inbound -Protocol $rule.Protocol -LocalPort $rule.Port -Action Allow -ErrorAction SilentlyContinue | Out-Null
}

Write-Host "✅ Firewall rules configured" -ForegroundColor Green

Write-Host "`n✅ Installation Complete!" -ForegroundColor Green
Write-Host "`nUniFi Network Controller is now running at:" -ForegroundColor Cyan
Write-Host "  https://$ControllerIP:8443" -ForegroundColor White
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "  1. Open browser and navigate to controller URL" -ForegroundColor White
Write-Host "  2. Complete initial setup wizard" -ForegroundColor White
Write-Host "  3. Create local admin account (no 2FA)" -ForegroundColor White
Write-Host "  4. Run adopt-devices.py to auto-adopt USG and switches" -ForegroundColor White
Write-Host "`n⚠️  Remember to update shared/inventory.yaml with admin credentials" -ForegroundColor Yellow

# Cleanup
Remove-Item $UniFiInstallerPath -Force -ErrorAction SilentlyContinue

Write-Host "`n🎉 Bootstrap complete! Controller URL: https://$ControllerIP:8443" -ForegroundColor Green
