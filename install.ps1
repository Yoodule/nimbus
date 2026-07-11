<#
.SYNOPSIS
Nimbus Installer - Windows Edition
Usage: irm https://raw.githubusercontent.com/Yoodule/nimbus/main/install.ps1 | iex
#>

$ErrorActionPreference = "Stop"
$Repo = "Yoodule/nimbus"
$InstallDir = if ($env:NIMBUS_HOME) { $env:NIMBUS_HOME } else { Join-Path $env:USERPROFILE ".nimbus" }

# Print the Nimbus brand mark as a **pre-baked stacked layout**:
# 26-line block-shading icon on top, 1 blank separator, 3-line
# text-block (wordmark / value prop / URL) centered within the
# 65-cell icon width, divider beneath — 31 rows total. Pre-baked
# by `nimbus-cli/build.rs` (writes `logo.banner`, copied to
# `release/banner.txt` by `scripts/release.sh`) and inlined into
# the literal-string heredoc below at release-build time (see
# the heredoc comment for the placeholder name). The runtime
# CLI's `print_banner` uses `banner::build_banner_lines` instead
# so it can pick layout by terminal width; the install banner is
# the brand's "best foot forward" — 65 cells, fixed, always
# renders the same shape.
#
# TTY gating: PowerShell doesn't have a portable equivalent to bash's
# `test -t 1`, and the `irm | iex` path means `$Host` here is the
# IEX pipeline host, not a real TTY. We just print the banner
# unconditionally — block-shading characters are valid output even
# when piped into a file (modern terminals and log scrapers preserve
# UTF-8 glyphs).
#
# The 2-space indent on each body line is baked into the file by
# build.rs (writes `logo.banner`) so the icon column-aligns with
# the 2-space-indented install text below (`  Preparing your
# environment...`).
$Banner = @'
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████▒░▓█████████████████████████████████████████
  █████████████████████  ░███████████████████▓ ░███████████████████
  ████████████████▒░░░     ░░░▓███████████▓░░    ░▒████████████████
  ████████████████▓▓▒░     ░▒▓██████▓▓█████▓▒   ▒▓▓████████████████
  █████████████████████  ░█████████   ███████▓░▒███████████████████
  █████████████████████▒░▓████████▒   ▒████████████████████████████
  ███████████████████████████████░     ░███████████████████████████
  ███████████████████████████▓▒           ▒▓███████████████████████
  ██████████████████████░                       ░██████████████████
  █████████████████████████▓▒░             ░▒▓█████████████████████
  ██████████████████████████████▒       ▒██████████████████████████
  ████████████████████████████████░   ▒████████████████████████████
  █████████████████████████████████   █████████████████████████████
  █████████████████████████████████▓░▒█████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
  █████████████████████████████████████████████████████████████████
                                                                   
                     NIMBUS — Your 24/7 Employee
   One command. No sign-up. The unified semantic gateway for MCP.
                     https://nimbus.yoodule.com
  ─────────────────────────────────────────────────────────────────
'@
Write-Host ""
Write-Host $Banner
Write-Host "  Preparing your environment..."

# 1. System Check
# Note: Windows 11 ARM64 natively emulates x86_64 binaries. Since we do not
# currently build a native windows-arm64 target in release.sh, we fall back
# to windows-amd64 on ARM64 systems.
$Arch = "amd64"
$DetectArch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "amd64" }
$OsName = "windows"

if ($DetectArch -eq "arm64") {
    Write-Host "  Detecting system... Done ($OsName-$DetectArch -> falling back to amd64 emulation)" -ForegroundColor Blue
} else {
    Write-Host "  Detecting system... Done ($OsName-$Arch)" -ForegroundColor Blue
}

$IsSource = $false

# 2. Local-repo dev install: build the Rust CLI + sync gateway source
# into $InstallDir. Only works when run from a clone of the gateway
# repo (i.e. the dev's own machine), never from `irm | iex`.
if ((Test-Path "nimbus-cli/Cargo.toml") -and (Test-Path "src")) {
    Write-Host "  Local repository detected. Building CLI + installing from source..."
    if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }

    Write-Host "  Compiling nimbus (cargo build --release)... " -NoNewline
    Push-Location nimbus-cli
    try {
        cargo build --release | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "cargo build failed" }
    } finally {
        Pop-Location
    }
    Copy-Item "nimbus-cli/target/release/nimbus.exe" -Destination (Join-Path $InstallDir "nimbus.exe") -Force
    Write-Host "Done" -ForegroundColor Blue

    # Sync gateway source + servers + mcp.json so the CLI's
    # `start` can mount them into the container via compose.yaml's
    # dev bind mounts. The release compose.yaml doesn't need these
    # because the gateway image is self-contained.
    Write-Host "  Syncing gateway source... " -NoNewline
    $Items = @("src", "servers", "mcp.json", "pyproject.toml", "uv.lock", "docker", "compose.yaml")
    foreach ($i in $Items) {
        if (Test-Path $i) {
            Copy-Item $i -Destination $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "Done" -ForegroundColor Blue

    $BinaryName = "nimbus.exe"
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

# 4.5 First-run .env stub. Same logic as install.sh — write a stub
# $NIMBUS_HOME\.env on first install so `nimbus start` doesn't crash
# on a missing env file. Skip if the file already exists.
#
# We do NOT generate real values for any secret. Only structural
# defaults get non-empty values — the rest are empty placeholders
# the user can populate. Three keys (BETTER_AUTH_SECRET,
# QDRANT_API_KEY, OPENROUTER_API_KEY) are intentionally OMITTED from
# this stub: the first two are auto-generated by `nimbus start`
# (or `nimbus env-init`) so the Better Auth dashboard sees a real,
# crypto-strong secret from first boot, and the third is prompted
# for interactively on first start. Writing `KEY=` for any of them
# would short-circuit those paths because the lookup would find
# the key (with an empty value) and skip generation.
# The file is restricted to the current user (Windows equivalent
# of chmod 0600) because it WILL hold real secrets once populated.
$EnvFile = Join-Path $InstallDir ".env"
if (-not (Test-Path $EnvFile)) {
    $Stub = @'
# Nimbus runtime config — generated by install.ps1 on first install.
# Paste your real values into the empty fields, then run `nimbus start`.
# See https://nimbus.yoodule.com for the full list of integrations.

# --- Secrets (paste your real values) ---
# BETTER_AUTH_SECRET and QDRANT_API_KEY are auto-generated by
# `nimbus start` / `nimbus env-init` on first run.
# OPENROUTER_API_KEY is prompted for interactively on first start.
UPWORK_REDIRECT_URI=
UPWORK_CLIENT_ID=
NIMBUS_APPROVED=
EXA_API_KEY=
POLYGON_RPC_URL=
NIMBUS_USER_EMAIL=
NIMBUS_USER_NAME=
NIMBUS_API_KEY=
GITHUB_TOKEN=
CLOUDFLARE_API_TOKEN=
CLOUDFLARE_ZONE_ID=
NIMBUS_ADMIN_PASSWORD=
POLYMARKET_PRIVATE_KEY=
NIMBUS_RUN_MODE=
UPWORK_API_KEY_NAME=
UPWORK_ACCOUNT_TYPE=
UPWORK_CLIENT_SECRET=
NIMBUS_OPENROUTER_KEY=
UPWORK_PERMISSIONS=
MINISIGN_SECRET_KEY_FILE=

# --- Structural defaults (runtime needs these) ---
GATEWAY_PORT=8088
QDRANT_URL=http://qdrant:6333
EMBEDDING_MODEL=nvidia/llama-nemotron-embed-vl-1b-v2:free
NIMBUS_DOMAIN=localhost
NIMBUS_GATEWAY_URL=http://localhost:8088/mcp
'@
    # -NoNewline matters: without it PowerShell appends a trailing
    # CRLF that breaks the KEY=VALUE parser in
    # nimbus-cli/src/main.rs:load_env_file.
    Set-Content -Path $EnvFile -Value $Stub -Encoding UTF8 -NoNewline
    # Restrict to current user — same pattern as project-cli-config-file.md
    $Acl = Get-Acl $EnvFile
    $Acl.SetAccessRuleProtection($true, $false)
    $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $env:USERNAME, "FullControl", "Allow")
    $Acl.AddAccessRule($Rule)
    Set-Acl $EnvFile $Acl
    Write-Host "  Created $EnvFile — paste your API keys before first start"
}

# 5. Shell Setup
# (no-op wrapper needed: the dev branch above already dropped a real
# nimbus.exe at $InstallDir\nimbus.exe, so we use it as-is. The
# $IsSource flag is kept for any future code that branches on it.)
$FinalBinary = "nimbus.exe"

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
    & ".\nimbus.exe" start
} else {
    Write-Host "  To start later, open a new PowerShell and type:"
    Write-Host "  nimbus start`n"
}
