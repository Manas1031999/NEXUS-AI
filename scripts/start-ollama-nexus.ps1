$ErrorActionPreference = "Stop"

$ContainerName = "nexus-ollama"
$ImageName = "ollama/ollama:latest"
$VolumeName = "nexus_ollama"
$ModelName = "qwen2.5:1.5b"
$BaseUrl = "http://localhost:11434"

Write-Host "`n=== NEXUS AI | Ollama Docker Startup ===" -ForegroundColor Cyan

# 1. Verify Docker CLI and Docker Engine
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker CLI was not found. Install/start Docker Desktop, then reopen PowerShell."
}

try {
    docker info *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Engine is not responding."
    }
}
catch {
    throw "Docker Engine is unavailable. Start Docker Desktop and make sure it is using Linux containers. Details: $($_.Exception.Message)"
}

Write-Host "[OK] Docker Engine is running." -ForegroundColor Green

# 2. Create persistent model storage volume if needed
$volumeExists = docker volume ls --format "{{.Name}}" | Where-Object { $_ -eq $VolumeName }
if (-not $volumeExists) {
    docker volume create $VolumeName | Out-Null
    Write-Host "[OK] Created Docker volume: $VolumeName" -ForegroundColor Green
}
else {
    Write-Host "[OK] Reusing Docker volume: $VolumeName" -ForegroundColor Green
}

# 3. Start existing container or create a new one
$containerExists = docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq $ContainerName }

if ($containerExists) {
    $running = docker ps --format "{{.Names}}" | Where-Object { $_ -eq $ContainerName }

    if (-not $running) {
        docker start $ContainerName | Out-Null
        Write-Host "[OK] Started existing container: $ContainerName" -ForegroundColor Green
    }
    else {
        Write-Host "[OK] Container is already running: $ContainerName" -ForegroundColor Green
    }
}
else {
    docker run -d `
        --name $ContainerName `
        --restart unless-stopped `
        -p 127.0.0.1:11434:11434 `
        -v "${VolumeName}:/root/.ollama" `
        $ImageName | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw "Could not create Ollama container."
    }

    Write-Host "[OK] Created and started Ollama container." -ForegroundColor Green
}

# 4. Wait for Ollama API to become available
Write-Host "`nWaiting for Ollama API at $BaseUrl ..." -ForegroundColor Yellow
$apiReady = $false

for ($i = 1; $i -le 60; $i++) {
    try {
        $null = Invoke-RestMethod -Uri "$BaseUrl/api/tags" -Method Get -TimeoutSec 3
        $apiReady = $true
        break
    }
    catch {
        Start-Sleep -Seconds 2
    }
}

if (-not $apiReady) {
    docker logs --tail 40 $ContainerName
    throw "Ollama API did not become ready within 120 seconds. See container logs above."
}

Write-Host "[OK] Ollama API is responding." -ForegroundColor Green

# 5. Download model only if it is not already present
$modelList = docker exec $ContainerName ollama list
if ($LASTEXITCODE -ne 0) {
    throw "Could not query models inside the Ollama container."
}

if (($modelList -join "`n") -notmatch [regex]::Escape($ModelName)) {
    Write-Host "`nDownloading model $ModelName (first run may take a while)..." -ForegroundColor Yellow
    docker exec $ContainerName ollama pull $ModelName

    if ($LASTEXITCODE -ne 0) {
        throw "Model download failed. Check your internet connection and run this script again."
    }
}
else {
    Write-Host "[OK] Model already downloaded: $ModelName" -ForegroundColor Green
}

# 6. Verify generation through the host API
Write-Host "`nTesting a short local response..." -ForegroundColor Yellow
$payload = @{
    model  = $ModelName
    prompt = "Reply with exactly: NEXUS AI local model is ready."
    stream = $false
} | ConvertTo-Json -Depth 5

try {
    $result = Invoke-RestMethod `
        -Uri "$BaseUrl/api/generate" `
        -Method Post `
        -ContentType "application/json" `
        -Body $payload `
        -TimeoutSec 180
}
catch {
    throw "Ollama API is up, but model generation failed: $($_.Exception.Message)"
}

Write-Host "`n=== SUCCESS ===" -ForegroundColor Green
Write-Host "Container : $ContainerName"
Write-Host "Model     : $ModelName"
Write-Host "API       : $BaseUrl"
Write-Host "Response  : $($result.response)"
Write-Host "`nOllama is running in Docker. Keep Docker Desktop open while using NEXUS AI." -ForegroundColor Green
