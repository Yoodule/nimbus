<#
.SYNOPSIS
Nimbus Installer - Windows Edition
Usage: irm https://raw.githubusercontent.com/Yoodule/nimbus/main/install.ps1 | iex
#>

$ErrorActionPreference = "Stop"
$Repo = "Yoodule/nimbus"
$InstallDir = if ($env:NIMBUS_HOME) { $env:NIMBUS_HOME } else { Join-Path $env:USERPROFILE ".nimbus" }

Write-Host "`n      N  I  M  B  U  S`n" -ForegroundColor Cyan
Write-Host "  Preparing your environment..."

# 1. System Check
$Arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "amd64" }
$OsName = "windows"
Write-Host "  Detecting system... Done ($OsName-$Arch)" -ForegroundColor Blue

$IsSource = $false

# 2. Check if we are in a local repo for Dev Install
if ((Test-Path "nimbus.py") -and (Test-Path "src")) {
    Write-Host "  Local repository detected. Installing from source..."
    if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
    
    Write-Host "  Syncing files... " -NoNewline
    Copy-Item "nimbus.py", "pyproject.toml", "uv.lock" -Destination $InstallDir -ErrorAction SilentlyContinue
    if (Test-Path "src") { Copy-Item -Path "src" -Destination $InstallDir -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path "dist") { Copy-Item -Path "dist\*" -Destination $InstallDir -Recurse -Force -ErrorAction SilentlyContinue }
    Write-Host "Done" -ForegroundColor Blue

    $BinaryName = "nimbus.py"
    $IsSource = $true
} else {
    # 2. Fetching Release
    Write-Host "  Fetching latest release... " -NoNewline
    $ReleaseUrl = "https://api.github.com/repos/$Repo/releases/latest"
    try {
        # Force TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $ReleaseData = Invoke-RestMethod -Uri $ReleaseUrl -UseBasicParsing
    } catch {
        Write-Host "`n  Error: Failed to fetch release data from GitHub." -ForegroundColor Red
        exit 1
    }

    $Version = $ReleaseData.tag_name
    $Asset = $ReleaseData.assets | Where-Object { $_.name -match "$OsName-$Arch" -and $_.name -match "\.(tar\.gz|zip)$" } | Select-Object -First 1

    if (-not $Asset) {
        Write-Host "`n  Error: Platform not supported ($OsName-$Arch) in release $Version." -ForegroundColor Red
        Write-Host "  Please build from source: https://github.com/Yoodule/nimbus"
        exit 1
    }

    Write-Host $Version -ForegroundColor Blue

    # 3. Downloading
    Write-Host "  Downloading assets..."
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    $TmpFile = Join-Path $env:TEMP $Asset.name
    Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $TmpFile -UseBasicParsing

    # 4. Extracting
    Write-Host "  Installing Nimbus... " -NoNewline
    if ($TmpFile -match "\.tar\.gz$") {
        # Windows 10+ natively supports tar
        tar -xzf $TmpFile -C $InstallDir
    } elseif ($TmpFile -match "\.zip$") {
        Expand-Archive -Path $TmpFile -DestinationPath $InstallDir -Force
    }
    Remove-Item $TmpFile -Force
    Write-Host "Success" -ForegroundColor Blue

    $IsSource = $false
}

# 5. Shell Setup
if ($IsSource) {
    # Create a wrapper .bat or .ps1 if installing from source
    $WrapperScript = Join-Path $InstallDir "nimbus.bat"
    Set-Content -Path $WrapperScript -Value "@echo off`npython `"%NIMBUS_HOME%\nimbus.py`" %*"
    $FinalBinary = "nimbus.bat"
} else {
    $BinaryPath = Join-Path $InstallDir "nimbus.exe"
    if (-not (Test-Path $BinaryPath)) {
        # Try finding the OS-specific named binary
        $AltBinary = Join-Path $InstallDir "nimbus-$OsName-$Arch.exe"
        if (Test-Path $AltBinary) {
            Rename-Item -Path $AltBinary -NewName "nimbus.exe"
        }
    }
    $FinalBinary = "nimbus.exe"
}

# Update User PATH if needed
$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath -notmatch [regex]::Escape($InstallDir)) {
    $NewPath = "$InstallDir;$UserPath"
    [Environment]::SetEnvironmentVariable("PATH", $NewPath, "User")
    # Also update current process so it works immediately
    $env:PATH = "$InstallDir;$env:PATH"
    Write-Host "  Added Nimbus to your User PATH"
}

# Add NIMBUS_HOME
if (-not [Environment]::GetEnvironmentVariable("NIMBUS_HOME", "User")) {
    [Environment]::SetEnvironmentVariable("NIMBUS_HOME", $InstallDir, "User")
    $env:NIMBUS_HOME = $InstallDir
}

Write-Host "`n  Nimbus is ready to go." -ForegroundColor Cyan
Write-Host "  Note: You may need to restart your terminal for PATH changes to take full effect.`n" -ForegroundColor DarkCyan

# 6. Auto-start option
$Response = Read-Host "  Would you like to start Nimbus now? (y/N)"
if ($Response -match "^[Yy]$") {
    Write-Host "  Starting Nimbus..."
    Set-Location $InstallDir
    if ($IsSource) {
        & ".\nimbus.bat" start
    } else {
        & ".\nimbus.exe" start
    }
} else {
    Write-Host "  To start later, open a new PowerShell and type:"
    Write-Host "  nimbus start`n"
}
