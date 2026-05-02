# Update claude-statusline to the latest version on origin/main (Windows / PowerShell).
# Usage:  powershell -ExecutionPolicy Bypass -File .\update.ps1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ScriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetDir    = Join-Path $env:USERPROFILE '.claude'
$TargetScript = Join-Path $TargetDir 'statusline.sh'

function Write-Info($msg)  { Write-Host "-> $msg" -ForegroundColor Green }
function Write-Warn2($msg) { Write-Host "!  $msg" -ForegroundColor Yellow }

Set-Location $ScriptDir

if (-not (Test-Path (Join-Path $ScriptDir '.git'))) {
    Write-Warn2 "Not a git checkout - skipping git pull. Re-run install.ps1 manually if you want to copy a fresh script."
    exit 0
}

$OldHead = (& git rev-parse HEAD 2>$null)
Write-Info "Pulling latest changes..."
& git pull --ff-only

$NewHead = (& git rev-parse HEAD 2>$null)

if ($OldHead -eq $NewHead) {
    Write-Info "Already up to date ($((& git rev-parse --short HEAD)))."
} else {
    Write-Info "Updated $((& git rev-parse --short $OldHead)) -> $((& git rev-parse --short $NewHead))"
}

# Delegate to install.ps1 so the .cmd wrapper, settings.json command, and
# any future generated artifacts stay in sync with the script.
$InstallScript = Join-Path $ScriptDir 'install.ps1'
if (Test-Path $InstallScript) {
    Write-Info "Re-running installer to refresh script + wrapper..."
    & $InstallScript
} else {
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir | Out-Null
    }
    Copy-Item (Join-Path $ScriptDir 'statusline.sh') $TargetScript -Force
    Write-Info "Refreshed $TargetScript"
}

$VersionPath = Join-Path $ScriptDir 'VERSION'
if (Test-Path $VersionPath) {
    $version = (Get-Content -Raw -Path $VersionPath).Trim()
    if ($version) { Write-Info "Now running version $version" }
}
