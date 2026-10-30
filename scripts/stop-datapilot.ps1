$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot

foreach ($port in 3000, 8065) {
    $listeners = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
    foreach ($listener in $listeners) {
        Stop-Process -Id $listener.OwningProcess -Force -ErrorAction SilentlyContinue
    }
}

$launcherFile = Join-Path $projectRoot '.local-run\backend-launcher.pid'
if (Test-Path -LiteralPath $launcherFile) {
    $launcherPid = [int](Get-Content -LiteralPath $launcherFile -Raw)
    Stop-Process -Id $launcherPid -Force -ErrorAction SilentlyContinue
}

$frontendFile = Join-Path $projectRoot '.local-run\frontend.pid'
if (Test-Path -LiteralPath $frontendFile) {
    $frontendPid = [int](Get-Content -LiteralPath $frontendFile -Raw)
    Stop-Process -Id $frontendPid -Force -ErrorAction SilentlyContinue
}

$composeFiles = @(
    '-f', (Join-Path $projectRoot 'docker-file\docker-compose.yml'),
    '-f', (Join-Path $projectRoot 'docker-file\docker-compose.local.yml')
)
& docker compose @composeFiles stop mysql mysql-data postgres-data

Write-Host 'DataPilot application processes and database containers are stopped.'
