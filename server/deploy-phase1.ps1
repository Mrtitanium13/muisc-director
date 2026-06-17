# Phase 1: deploy Music Director API to Railway (testing).
# Prereqs: Node/npm (for Railway CLI), Railway account.
# One-time: run `railway login` when this script tells you.

$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

Write-Host "=== Music Director API -> Railway ===" -ForegroundColor Cyan

if (-not (Get-Command railway -ErrorAction SilentlyContinue)) {
  Write-Host "Installing Railway CLI..." -ForegroundColor Yellow
  npm install -g @railway/cli
}

railway whoami *> $null 2>&1
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "NOT LOGGED IN. Run this in the same folder, then re-run this script:" -ForegroundColor Yellow
  Write-Host "  railway login" -ForegroundColor White
  Write-Host ""
  exit 1
}

$who = railway whoami 2>&1 | Out-String
Write-Host "Logged in: $($who.Trim())" -ForegroundColor Green

if (-not (Test-Path ".railway")) {
  Write-Host "Creating Railway project (music-director-api)..." -ForegroundColor Cyan
  railway init -n "music-director-api"
  if ($LASTEXITCODE -ne 0) {
    Write-Host "railway init failed." -ForegroundColor Red
    exit $LASTEXITCODE
  }
}

Write-Host "Deploying (Dockerfile)..." -ForegroundColor Cyan
railway up
if ($LASTEXITCODE -ne 0) {
  Write-Host "Deploy failed." -ForegroundColor Red
  exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Post-deploy:" -ForegroundColor Cyan
Write-Host "  - Set OpenAI on Railway (required for /generate-prompt):" -ForegroundColor White
Write-Host "      `$env:OPENAI_API_KEY = 'sk-...'; .\set-openai-railway.ps1" -ForegroundColor Gray
Write-Host "  - Networking: public HTTPS URL (copy for MD_API_BASE_URL in the Flutter app)"
Write-Host ""

if ($env:OPENAI_API_KEY -and $env:OPENAI_API_KEY.Trim().Length -gt 0) {
  Write-Host "OPENAI_API_KEY is set in this shell — pushing to Railway..." -ForegroundColor Cyan
  & "$PSScriptRoot\set-openai-railway.ps1"
}
