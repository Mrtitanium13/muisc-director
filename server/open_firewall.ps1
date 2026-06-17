# Run once as Administrator so phones on Wi-Fi can reach uvicorn on port 8080.
# Right-click → Run with PowerShell, or: Start-Process powershell -Verb RunAs -ArgumentList '-File', $PSScriptRoot\open_firewall.ps1

$ErrorActionPreference = 'Stop'
$ruleName = 'Music Director API 8080'

$existing = netsh advfirewall firewall show rule name="$ruleName" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Firewall rule already exists: $ruleName" -ForegroundColor Green
    exit 0
}

netsh advfirewall firewall add rule `
    name="$ruleName" `
    dir=in `
    action=allow `
    protocol=TCP `
    localport=8080 `
    profile=private,domain

Write-Host "Added inbound rule for TCP port 8080 (private + domain networks)." -ForegroundColor Green
Write-Host "Phone URL example: http://$(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like '192.168.*' } | Select-Object -First 1 -ExpandProperty IPAddress):8080"
