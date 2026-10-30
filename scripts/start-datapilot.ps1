$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$runDir = Join-Path $projectRoot '.local-run'
$composeFiles = @(
    '-f', (Join-Path $projectRoot 'docker-file\docker-compose.yml'),
    '-f', (Join-Path $projectRoot 'docker-file\docker-compose.local.yml')
)

New-Item -ItemType Directory -Force -Path $runDir | Out-Null

& (Join-Path $PSScriptRoot 'start-docker-datapilot.ps1')

$dockerDeadline = (Get-Date).AddMinutes(2)
$dockerReady = $false
while ((Get-Date) -lt $dockerDeadline) {
    try {
        docker info *> $null
        $dockerReady = $LASTEXITCODE -eq 0
    }
    catch {
        $dockerReady = $false
    }
    if ($dockerReady) { break }
    Start-Sleep -Seconds 2
}
if (-not $dockerReady) {
    throw 'Docker Engine did not become ready within two minutes.'
}

if (-not (Test-Path Env:AI_DASHSCOPE_API_KEY)) {
    $env:AI_DASHSCOPE_API_KEY = ''
}

& docker compose @composeFiles up -d --wait --wait-timeout 120 mysql mysql-data postgres-data
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to start the database containers.'
}

$jar = Join-Path $projectRoot 'data-agent-management\target\spring-ai-alibaba-data-agent-management-1.0.0-SNAPSHOT.jar'
if (-not (Test-Path -LiteralPath $jar)) {
    Push-Location $projectRoot
    try {
        & .\mvnw.cmd -s .mvn\datapilot-settings.xml -pl data-agent-management -DskipTests package
        if ($LASTEXITCODE -ne 0) { throw 'Backend build failed.' }
    }
    finally {
        Pop-Location
    }
}

$frontendDir = Join-Path $projectRoot 'data-agent-frontend-nuxt'
$frontendEntry = Join-Path $frontendDir '.output\server\index.mjs'
if (-not (Test-Path -LiteralPath $frontendEntry)) {
    Push-Location $frontendDir
    try {
        & pnpm install --frozen-lockfile
        if ($LASTEXITCODE -ne 0) { throw 'Frontend dependency installation failed.' }
        & pnpm build
        if ($LASTEXITCODE -ne 0) { throw 'Frontend build failed.' }
    }
    finally {
        Pop-Location
    }
}

$backendListener = Get-NetTCPConnection -State Listen -LocalPort 8065 -ErrorAction SilentlyContinue
if (-not $backendListener) {
    $env:DATA_AGENT_DATASOURCE_URL = 'jdbc:mysql://127.0.0.1:13307/nl2sql_db?useUnicode=true&characterEncoding=utf-8&zeroDateTimeBehavior=convertToNull&transformedBitIsBoolean=true&allowMultiQueries=true&allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=Asia/Shanghai'
    $env:DATA_AGENT_DATASOURCE_USERNAME = 'root'
    $env:DATA_AGENT_DATASOURCE_PASSWORD = 'root'
    $env:DATA_AGENT_DATASOURCE_SQL_INIT = 'always'
    $quotedJar = '"' + $jar + '"'
    $backend = Start-Process -FilePath 'java' -ArgumentList '-jar', $quotedJar `
        -WorkingDirectory $projectRoot -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $runDir 'backend.out.log') `
        -RedirectStandardError (Join-Path $runDir 'backend.err.log') -PassThru
    Set-Content -LiteralPath (Join-Path $runDir 'backend-launcher.pid') -Value $backend.Id
}

$frontendListener = Get-NetTCPConnection -State Listen -LocalPort 3000 -ErrorAction SilentlyContinue
if (-not $frontendListener) {
    $env:NITRO_HOST = '127.0.0.1'
    $env:NITRO_PORT = '3000'
    $frontend = Start-Process -FilePath 'node' -ArgumentList '.output/server/index.mjs' `
        -WorkingDirectory $frontendDir -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $runDir 'frontend.out.log') `
        -RedirectStandardError (Join-Path $runDir 'frontend.err.log') -PassThru
    Set-Content -LiteralPath (Join-Path $runDir 'frontend.pid') -Value $frontend.Id
}

$readyDeadline = (Get-Date).AddMinutes(1)
$backendReady = $false
$frontendReady = $false
while ((Get-Date) -lt $readyDeadline) {
    try {
        $backendReady = (Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:8065/echo/ok' -TimeoutSec 3).StatusCode -eq 200
    }
    catch { $backendReady = $false }
    try {
        $frontendReady = (Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:3000/' -TimeoutSec 3).StatusCode -eq 200
    }
    catch { $frontendReady = $false }
    if ($backendReady -and $frontendReady) { break }
    Start-Sleep -Seconds 2
}

if (-not $backendReady -or -not $frontendReady) {
    throw "DataPilot did not become ready. Check logs under $runDir"
}

Write-Host 'DataPilot is ready:'
Write-Host '  UI:      http://127.0.0.1:3000'
Write-Host '  API:     http://127.0.0.1:8065'
Write-Host '  Swagger: http://127.0.0.1:8065/swagger-ui.html'
