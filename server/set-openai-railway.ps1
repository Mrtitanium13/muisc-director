# Sets OPENAI_API_KEY on the Railway service `music-director-api` (fixes 503 on /generate-prompt).
# The key is sent via stdin so it does not appear in process listings.
#
# Usage (PowerShell):
#   $env:OPENAI_API_KEY = 'sk-...'   # paste from https://platform.openai.com/api-keys
#   .\set-openai-railway.ps1
#
# Prereqs: `railway login` once; this folder should be linked (deploy-phase1 or `railway service link music-director-api`).

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Get-Command railway -ErrorAction SilentlyContinue)) {
  Write-Error "Railway CLI not found. Install: npm install -g @railway/cli"
  exit 1
}

railway whoami *> $null 2>&1
if ($LASTEXITCODE -ne 0) {
  Write-Host "Run: railway login" -ForegroundColor Yellow
  exit 1
}

railway service link music-director-api 2>$null

$key = $env:OPENAI_API_KEY
if (-not $key -or $key.Trim().Length -eq 0) {
  Write-Host "Set OPENAI_API_KEY in this shell first, e.g.:" -ForegroundColor Yellow
  Write-Host '  $env:OPENAI_API_KEY = "sk-..."' -ForegroundColor White
  Write-Host "Then run this script again." -ForegroundColor Yellow
  exit 2
}

$key.Trim() | railway variables set OPENAI_API_KEY --stdin
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host "OPENAI_API_KEY set on Railway. A redeploy may run automatically; wait, then try Generate prompt again." -ForegroundColor Green
