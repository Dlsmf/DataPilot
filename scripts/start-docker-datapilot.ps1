$ErrorActionPreference = 'Stop'

$runtimeRoot = 'D:\DockerRuntimeDataPilot'
$dockerDesktop = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'

if (-not (Test-Path -LiteralPath $runtimeRoot)) {
    New-Item -ItemType Directory -Path $runtimeRoot | Out-Null
}

if (-not (Test-Path -LiteralPath $dockerDesktop)) {
    throw "Docker Desktop was not found at: $dockerDesktop"
}

$backend = Get-Process -Name 'com.docker.backend' -ErrorAction SilentlyContinue
if (-not $backend) {
    $originalLocalAppData = $env:LOCALAPPDATA
    try {
        $env:LOCALAPPDATA = $runtimeRoot
        Start-Process -FilePath $dockerDesktop -WindowStyle Hidden
    }
    finally {
        $env:LOCALAPPDATA = $originalLocalAppData
    }
}

Write-Host "Docker Desktop is using isolated runtime data at $runtimeRoot"
