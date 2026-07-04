<#
.SYNOPSIS
Nimbus Installer - Windows Edition
Usage: irm https://nimbus.yoodule.com/install.ps1 | iex
  Pin a version:  $env:NIMBUS_VERSION = "vX.Y.Z"; irm ... | iex
#>

$ErrorActionPreference = "Stop"
$Repo = "Yoodule/nimbus"

# Install dir: $env:NIMBUS_HOME if set, else %USERPROFILE%\.nimbus
$InstallDir = if ($env:NIMBUS_HOME) { $env:NIMBUS_HOME } else { Join-Path $env:USERPROFILE ".nimbus" }

# --- Aesthetics (Yoodule Style: High Contrast, Minimalist) ---
# PowerShell's Write-Host -ForegroundColor only supports a fixed palette, so we
# approximate the bash colors: Cyan = the WHITE bold lines, DarkCyan = the DIM
# separator, Blue = status text, DarkYellow = error.
function Write-Banner {
    Write-Host ""
    Write-Host "  NIMBUS" -ForegroundColor Cyan
    Write-Host "  Your 24/7 Employee" -ForegroundColor Cyan
    Write-Host "  https://nimbus.yoodule.com" -ForegroundColor Cyan
    Write-Host "  --------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Preparing your environment..."
}

function Format-Bytes {
    param([long]$Bytes)
    $units = @("B", "KB", "MB", "GB", "TB")
    $i = 0
    $b = [double]$Bytes
    while ($b -ge 1024 -and $i -lt 4) { $b /= 1024; $i++ }
    return ("{0:N1} {1}" -f $b, $units[$i])
}

# Single-line progress bar, redrawn in place. PowerShell's [Console] cursor
# APIs are limited; we use CR (`r) to overwrite the current line. We have to
# buffer the line and pad with spaces to clear leftover characters from the
# previous (longer) line.
function Write-ProgressBar {
    param(
        [string]$Name,
        [long]$Current,
        [long]$Total,
        [long]$Speed
    )
    if ($Total -gt 0) {
        $pct = [int](($Current * 100) / $Total)
        $filled = [int]($pct / 5)   # 20-char bar
        $empty = 20 - $filled
        $bar = ("#" * $filled) + ("-" * $empty)
        $line = "  {0,-22} [{1}] {2,3}%  {3} / {4}  {5}/s" -f `
            $Name, $bar, $pct, (Format-Bytes $Current), (Format-Bytes $Total), (Format-Bytes $Speed)
    } else {
        # Unknown total: spinner + bytes so far
        $spin = @('|', '/', '-', '\')
        $sidx = ([int]([DateTime]::Now.TimeOfDay.TotalSeconds) * 4) % 4
        $line = "  {0,-22} {1} {2} downloaded" -f $Name, $spin[$sidx], (Format-Bytes $Current)
    }
    # Pad to clear leftover characters on terminals that don't auto-erase
    $pad = " " * [Math]::Max(0, ([Console]::BufferWidth - $line.Length - 1))
    [Console]::Write("`r$line$pad")
}

# Download with a live progress bar. PowerShell's Invoke-WebRequest writes
# the file as it downloads (no streaming progress in older PS), so we
# shell out to [System.Net.Http.HttpClient] via .NET, which gives us a
# real per-chunk callback. Falls back to Invoke-WebRequest if HttpClient
# isn't available (PowerShell 5.1 has it; anything newer has it too).
function Download-WithProgress {
    param(
        [string]$Url,
        [string]$Name,
        [string]$OutFile
    )
    try {
        Add-Type -AssemblyName System.Net.Http -ErrorAction Stop
    } catch {
        # Fallback: just download without progress
        Write-Host "  $Name ... (no progress UI in this PS version)"
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
        return
    }

    $client = New-Object System.Net.Http.HttpClient
    try {
        $response = $client.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
        if (-not $response.IsSuccessStatusCode) {
            throw "HTTP $($response.StatusCode) for $Url"
        }
        $total = $response.Content.Headers.ContentLength
        if ($null -eq $total) { $total = 0 }

        $stream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        $fs = [System.IO.File]::Create($OutFile)
        try {
            $buffer = New-Object byte[] 65536
            $read = 0
            $bytes = 0L
            $lastTick = [DateTime]::UtcNow
            $lastBytes = 0L
            $speed = 0L
            while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $fs.Write($buffer, 0, $read)
                $bytes += $read
                $now = [DateTime]::UtcNow
                $dt = ($now - $lastTick).TotalSeconds
                if ($dt -ge 0.2) {
                    $speed = [long](($bytes - $lastBytes) / $dt)
                    $lastTick = $now
                    $lastBytes = $bytes
                    Write-ProgressBar -Name $Name -Current $bytes -Total ([long]$total) -Speed $speed
                }
            }
        } finally {
            $fs.Dispose()
            $stream.Dispose()
        }
        # Final 100% line
        if ($total -gt 0) {
            $bar = "#" * 20
            $line = "  {0,-22} [{1}] 100%  {2} / {3}        " -f `
                $Name, $bar, (Format-Bytes $total), (Format-Bytes $total)
        } else {
            $line = "  {0,-22} done  {1}                       " -f `
                $Name, (Format-Bytes $bytes)
        }
        [Console]::WriteLine("`r$line")
    } finally {
        $client.Dispose()
    }
}

function Get-Checksum {
    param([string]$SumsFile, [string]$AssetName)
    # SHA256SUMS is "<hex>  <filename>" (two spaces), case-sensitive on Windows.
    $line = Select-String -Path $SumsFile -Pattern "^[0-9a-f]{64}  $([regex]::Escape($AssetName))$" -SimpleMatch:$false | Select-Object -First 1
    if (-not $line) { return $null }
    return ($line -split '\s+')[0]
}

function Test-Checksum {
    param([string]$File, [string]$Expected)
    $actual = (Get-FileHash -Path $File -Algorithm SHA256).Hash.ToLower()
    return ($actual -eq $Expected.ToLower())
}

Write-Banner

# 1. System Check
$Arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "amd64" }
$OsName = "windows"
Write-Host "  Detecting system... " -NoNewline
Write-Host "Done ($OsName-$Arch)" -ForegroundColor Blue

# 2. Resolve version
# /releases/latest returns the newest non-draft, non-prerelease release.
# Frozen fallback used only when the API is unreachable.
Write-Host "  Fetching latest release... " -NoNewline
if (-not $env:NIMBUS_VERSION) {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $releaseData = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -UseBasicParsing
        $env:NIMBUS_VERSION = $releaseData.tag_name
    } catch {
        $env:NIMBUS_VERSION = "v1.0.3"
    }
}
if (-not $env:NIMBUS_VERSION) {
    Write-Host ""
    Write-Host "  Error: Could not resolve a release version. Set `$env:NIMBUS_VERSION = 'vX.Y.Z' and retry." -ForegroundColor DarkYellow
    exit 1
}
Write-Host $env:NIMBUS_VERSION -ForegroundColor Blue

$ReleaseBase = "https://github.com/$Repo/releases/download/$env:NIMBUS_VERSION"
$AssetName = "nimbus-$OsName-$Arch.tar.gz"
$DashboardAsset = "dashboard.tar.gz"
$ReleaseUrl = "$ReleaseBase/$AssetName"
$DashboardUrl = "$ReleaseBase/$DashboardAsset"
Write-Host $env:NIMBUS_VERSION -ForegroundColor Blue

# 3. Downloading + verifying
# Per-file progress bars are printed by Download-WithProgress; no generic
# "Downloading assets..." banner needed.
$TmpDir = Join-Path $env:TEMP "nimbus-install-$([System.Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $TmpDir -Force | Out-Null
$TmpFile = Join-Path $TmpDir $AssetName
$TmpDashboard = Join-Path $TmpDir $DashboardAsset
$TmpSums = Join-Path $TmpDir "SHA256SUMS"

# Fetch SHA256SUMS first so we can verify every asset against the same sidecar.
try {
    Invoke-WebRequest -Uri "$ReleaseBase/SHA256SUMS" -OutFile $TmpSums -UseBasicParsing | Out-Null
} catch {
    Write-Host ""
    Write-Host "  Error: Could not download SHA256SUMS for $env:NIMBUS_VERSION." -ForegroundColor DarkYellow
    Write-Host "  Verify the release at: $ReleaseBase"
    Remove-Item -Recurse -Force $TmpDir
    exit 1
}

function Download-And-Verify {
    param([string]$Url, [string]$Name, [string]$OutFile)
    try {
        Download-WithProgress -Url $Url -Name $Name -OutFile $OutFile
    } catch {
        Write-Host ""
        Write-Host "  Error: Download failed ($Name)." -ForegroundColor DarkYellow
        Write-Host "  URL: $Url"
        return $false
    }
    $expected = Get-Checksum -SumsFile $TmpSums -AssetName $Name
    if (-not $expected) {
        Write-Host "  Warning: No checksum found for $Name in SHA256SUMS, skipping verification." -ForegroundColor DarkYellow
        return $true
    }
    if (-not (Test-Checksum -File $OutFile -Expected $expected)) {
        Write-Host ""
        Write-Host "  Error: SHA256 verification failed for $Name." -ForegroundColor DarkYellow
        Write-Host "  Refusing to install. Verify the release at $ReleaseBase manually."
        return $false
    }
    Write-Host "  Checksum verified for $Name... " -NoNewline
    Write-Host "OK" -ForegroundColor Blue
    return $true
}

if (-not (Download-And-Verify -Url $ReleaseUrl -Name $AssetName -OutFile $TmpFile)) {
    Remove-Item -Recurse -Force $TmpDir
    exit 1
}

# 4. Extracting
Write-Host "  Installing Nimbus... " -NoNewline
if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
try {
    # Windows 10+ natively supports tar
    tar -xzf $TmpFile -C $InstallDir
} catch {
    Write-Host ""
    Write-Host "  Error: Extraction failed: $_" -ForegroundColor DarkYellow
    Remove-Item -Recurse -Force $TmpDir
    exit 1
}
Write-Host "Success" -ForegroundColor Blue

# 5. Optional dashboard install
# The dashboard ships as a separate tarball on the same release. The CLI starts
# fine without it (gateway is headless), but most users want it. Interactive:
# Enter accepts the default (yes); non-interactive (irm | iex) installs by default.
function Install-Dashboard {
    if (-not (Download-And-Verify -Url $DashboardUrl -Name $DashboardAsset -OutFile $TmpDashboard)) {
        Write-Host "  Skipping dashboard install (asset not available for this release)." -ForegroundColor DarkCyan
        return
    }
    try {
        tar -xzf $TmpDashboard -C $InstallDir
    } catch {
        Write-Host "  Skipping dashboard install (extraction failed)." -ForegroundColor DarkCyan
        return
    }
    Write-Host "  Dashboard installed at: $InstallDir\dashboard" -ForegroundColor Blue
}

# Check if the host has an interactive stdin. [Console]::IsInputRedirected
# is true when stdin is a pipe (irm | iex), false in an interactive session.
if ([Console]::IsInputRedirected) {
    # Non-interactive (irm | iex) — install by default.
    Install-Dashboard
} else {
    $reply = Read-Host "  Would you like to install the Nimbus Dashboard too? (Y/n)"
    if ($reply -notmatch "^[Nn]$") {
        Install-Dashboard
    } else {
        Write-Host "  Skipping dashboard install." -ForegroundColor DarkCyan
    }
}

# 6. Shell Setup
# Add NIMBUS_HOME + InstallDir to User PATH (idempotent).
$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$PathParts = if ($UserPath) { $UserPath -split ";" } else { @() }
if ($PathParts -notcontains $InstallDir) {
    $NewPath = if ($UserPath) { "$InstallDir;$UserPath" } else { $InstallDir }
    [Environment]::SetEnvironmentVariable("PATH", $NewPath, "User")
    $env:PATH = "$InstallDir;$env:PATH"
    Write-Host "  Added $InstallDir to your User PATH"
}
if (-not [Environment]::GetEnvironmentVariable("NIMBUS_HOME", "User")) {
    [Environment]::SetEnvironmentVariable("NIMBUS_HOME", $InstallDir, "User")
    $env:NIMBUS_HOME = $InstallDir
}

Write-Host ""
Write-Host "  Nimbus is ready to go." -ForegroundColor Cyan
Write-Host ""

# 7. Auto-start option
$Response = Read-Host "  Would you like to start Nimbus now? (y/N)"
if ($Response -match "^[Yy]$") {
    Write-Host "  Starting Nimbus..."
    Push-Location $InstallDir
    try { & ".\nimbus.exe" start } finally { Pop-Location }
} else {
    Write-Host "  To start later, open a new PowerShell and type:"
    Write-Host "  nimbus start" -ForegroundColor Cyan
    Write-Host ""
}
