
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Host "`n=== NEXUS AI | Stopping Ollama ===" -ForegroundColor Cyan

Set-Location $ProjectRoot

docker compose stop ollama

if ($LASTEXITCODE -ne 0) {
    throw "Failed to stop Ollama."
}

Write-Host "`n[OK] Ollama stopped." -ForegroundColor Green
Write-Host "Model and Docker volume are preserved."
