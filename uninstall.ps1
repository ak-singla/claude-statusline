# Uninstall claude-statusline (Windows / PowerShell native).
# Removes the statusLine block from settings.json and deletes the script.
# Leaves the cloned repo at its location - delete manually if desired.
# Usage:  powershell -ExecutionPolicy Bypass -File .\uninstall.ps1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetDir     = Join-Path $env:USERPROFILE '.claude'
$TargetScript  = Join-Path $TargetDir 'statusline.sh'
$TargetWrapper = Join-Path $TargetDir 'statusline.cmd'
$Settings      = Join-Path $TargetDir 'settings.json'

function Write-Info($msg)  { Write-Host "-> $msg" -ForegroundColor Green }
function Write-Warn2($msg) { Write-Host "!  $msg" -ForegroundColor Yellow }

if (Test-Path $Settings) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    Copy-Item $Settings "$Settings.bak.$stamp"

    $json = Get-Content -Raw -Path $Settings | ConvertFrom-Json
    if ($json.PSObject.Properties.Name -contains 'statusLine') {
        $json.PSObject.Properties.Remove('statusLine')
        ($json | ConvertTo-Json -Depth 32) | Set-Content -Path $Settings -Encoding utf8
        Write-Info "Removed statusLine block from $Settings"
    } else {
        Write-Warn2 "No statusLine block found in $Settings"
    }
}

if (Test-Path $TargetScript) {
    Remove-Item $TargetScript -Force
    Write-Info "Deleted $TargetScript"
}

if (Test-Path $TargetWrapper) {
    Remove-Item $TargetWrapper -Force
    Write-Info "Deleted $TargetWrapper"
}

Write-Info "Uninstalled. The repo clone is still on disk - remove it manually if you want: $ScriptDir"
