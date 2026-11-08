
$ErrorActionPreference = "Stop"

# Load PostgreSQL password securely
if ([string]::IsNullOrWhiteSpace($env:DB_PASSWORD)) {
    $securePassword = Read-Host "Enter PostgreSQL password" -AsSecureString
    $env:DB_PASSWORD = [System.Net.NetworkCredential]::new(
        "",
        $securePassword
    ).Password
}


# Load Gemini API key securely
if ([string]::IsNullOrWhiteSpace($env:GEMINI_API_KEY)) {
    $secureGeminiKey = Read-Host "Enter Gemini API key" -AsSecureString
    $env:GEMINI_API_KEY = [System.Net.NetworkCredential]::new(
        "",
        $secureGeminiKey
    ).Password
}

if ([string]::IsNullOrWhiteSpace($env:GEMINI_API_KEY)) {
    throw "Gemini API key is required."
}

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$BackendPath = Join-Path $ProjectRoot "backend\nexus-ai"
$PostgresService = "postgresql-x64-18"
$BaseUrl = "http://localhost:8080"
$HealthUrl = "$BaseUrl/api/v1/health"
$LogDir = Join-Path $ProjectRoot "logs"
$BackendLog = Join-Path $LogDir "backend.log"
$BackendErrorLog = Join-Path $LogDir "backend-error.log"
$PidFile = Join-Path $LogDir "backend.pid"

Write-Host "`n====================================" -ForegroundColor Cyan
Write-Host "       NEXUS AI STARTUP" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

Set-Location $ProjectRoot

# 1. Check Java
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    throw "Java not found. Install/configure Java 21."
}
Write-Host "[OK] Java available." -ForegroundColor Green

# 2. Start PostgreSQL
$pg = Get-Service -Name $PostgresService -ErrorAction Stop

if ($pg.Status -ne "Running") {
    Write-Host "Starting PostgreSQL..." -ForegroundColor Yellow
    Start-Service -Name $PostgresService
    (Get-Service -Name $PostgresService).WaitForStatus(
        "Running", [TimeSpan]::FromSeconds(30)
    )
}
Write-Host "[OK] PostgreSQL running." -ForegroundColor Green

# 3. Start Ollama
Write-Host "`nStarting Ollama..." -ForegroundColor Yellow

$OllamaScript = Join-Path $PSScriptRoot "start-ollama.ps1"

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $OllamaScript

if ($LASTEXITCODE -ne 0) {
    throw "Ollama startup failed."
}

# 4. Prepare logs
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

# 5. Check existing backend
$backendReady = $false

try {
    Invoke-RestMethod -Uri $HealthUrl -TimeoutSec 3 | Out-Null
    $backendReady = $true
    Write-Host "[OK] Backend is already running." -ForegroundColor Green
}
catch {
    Write-Host "`nStarting Spring Boot backend..." -ForegroundColor Yellow
}

# 6. Start backend if required
if (-not $backendReady) {

    if (Test-Path $PidFile) {
        $oldPid = Get-Content $PidFile -ErrorAction SilentlyContinue

        if ($oldPid -match '^\d+$') {
            $oldProcess = Get-CimInstance Win32_Process `
                -Filter "ProcessId = $oldPid" `
                -ErrorAction SilentlyContinue

            if ($oldProcess -and $oldProcess.CommandLine -match 'mvnw\.cmd') {
                throw "A Maven launcher already exists. Check backend logs before starting another instance."
            }
        }

        Remove-Item $PidFile -Force
    }

    $process = Start-Process `
        -FilePath "cmd.exe" `
        -ArgumentList "/c", "mvnw.cmd spring-boot:run" `
        -WorkingDirectory $BackendPath `
        -RedirectStandardOutput $BackendLog `
        -RedirectStandardError $BackendErrorLog `
        -PassThru

    Set-Content -Path $PidFile -Value $process.Id

    $backendReady = $false

    for ($i = 1; $i -le 90; $i++) {
        Start-Sleep -Seconds 2

        try {
            Invoke-RestMethod -Uri $HealthUrl -TimeoutSec 3 | Out-Null
            $backendReady = $true
            break
        }
        catch {
            if ($process.HasExited) {
                throw "Spring Boot launcher exited. Check logs/backend-error.log."
            }
        }
    }

    if (-not $backendReady) {
        throw "Backend did not become healthy within 180 seconds. Check logs."
    }
}

Write-Host "`n====================================" -ForegroundColor Green
Write-Host "       NEXUS AI IS READY!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host "Backend : $BaseUrl"
Write-Host "Health  : $HealthUrl"
Write-Host "AI      : Ollama / Qwen 2.5 1.5B"
Write-Host "`nLogs: $LogDir" -ForegroundColor Cyan
