
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ContainerName = "nexus-ollama"
$VolumeName = "nexus_ollama"
$ModelName = "qwen2.5:1.5b"
$BaseUrl = "http://localhost:11434"

Write-Host "`n=== NEXUS AI | Ollama Startup ===" -ForegroundColor Cyan

Set-Location $ProjectRoot

# 1. Verify Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker CLI not found. Start Docker Desktop."
}

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    throw "Docker Engine is unavailable. Start Docker Desktop."
}

Write-Host "[OK] Docker Engine is running." -ForegroundColor Green

# 2. Ensure persistent volume exists
$volumeExists = docker volume ls --format "{{.Name}}" |
    Where-Object { $_ -eq $VolumeName }

if (-not $volumeExists) {
    docker volume create $VolumeName | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create Docker volume."
    }
    Write-Host "[OK] Created volume: $VolumeName" -ForegroundColor Green
}
else {
    Write-Host "[OK] Reusing volume: $VolumeName" -ForegroundColor Green
}

# 3. Start through Docker Compose
docker compose up -d ollama

if ($LASTEXITCODE -ne 0) {
    throw "Docker Compose failed to start Ollama."
}

Write-Host "[OK] Ollama container started." -ForegroundColor Green

# 4. Wait for API
Write-Host "`nWaiting for Ollama API..." -ForegroundColor Yellow

$apiReady = $false

for ($i = 1; $i -le 60; $i++) {
    try {
        $null = Invoke-RestMethod `
            -Uri "$BaseUrl/api/tags" `
            -TimeoutSec 3

        $apiReady = $true
        break
    }
    catch {
        Start-Sleep -Seconds 2
    }
}

if (-not $apiReady) {
    docker logs --tail 40 $ContainerName
    throw "Ollama API did not become ready."
}

Write-Host "[OK] Ollama API is responding." -ForegroundColor Green

# 5. Check model
$modelList = docker exec $ContainerName ollama list

if ($LASTEXITCODE -ne 0) {
    throw "Could not retrieve Ollama model list."
}

if (($modelList -join "`n") -notmatch [regex]::Escape($ModelName)) {
    Write-Host "Downloading model: $ModelName" -ForegroundColor Yellow

    docker exec $ContainerName ollama pull $ModelName

    if ($LASTEXITCODE -ne 0) {
        throw "Model download failed."
    }
}
else {
    Write-Host "[OK] Model already downloaded: $ModelName" -ForegroundColor Green
}

# 6. Test actual AI inference
Write-Host "`nTesting AI inference..." -ForegroundColor Yellow

$payload = @{
    model = $ModelName
    prompt = "Reply with exactly: NEXUS AI local model is ready."
    stream = $false
    keep_alive = "30s"
    options = @{
        num_ctx = 1024
        num_predict = 30
        num_thread = 2
        temperature = 0.3
    }
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
    throw "AI inference failed: $($_.Exception.Message)"
}

if (-not $result.response) {
    throw "Ollama returned an empty response."
}

Write-Host "`n=== SUCCESS ===" -ForegroundColor Green
Write-Host "Container : $ContainerName"
Write-Host "Model     : $ModelName"
Write-Host "API       : $BaseUrl"
Write-Host "Response  : $($result.response)"
Write-Host "`nNEXUS AI local model is operational." -ForegroundColor Green
