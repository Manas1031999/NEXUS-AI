$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$LogDir = Join-Path $ProjectRoot "logs"
$PidFile = Join-Path $LogDir "backend.pid"

Write-Host "`n=== NEXUS AI SHUTDOWN ===" -ForegroundColor Cyan

# 1. Stop managed Spring Boot process tree
if (Test-Path $PidFile) {

    $backendPid = (Get-Content $PidFile -Raw).Trim()

    if ($backendPid -match '^\d+$') {

        $process = Get-CimInstance Win32_Process `
            -Filter "ProcessId = $backendPid" `
            -ErrorAction SilentlyContinue

        if ($process -and
            $process.Name -eq "cmd.exe" -and
            $process.CommandLine -match 'mvnw\.cmd') {

            & taskkill.exe /PID ([int]$backendPid) /T /F | Out-Null

            if ($LASTEXITCODE -ne 0) {
                throw "Could not stop the backend process tree."
            }

            Write-Host "[OK] Backend process tree stopped." -ForegroundColor Green
        }
        else {
            Write-Host "[INFO] Managed backend launcher is not running." -ForegroundColor Yellow
        }
    }

    Remove-Item $PidFile -Force
}
else {
    Write-Host "[INFO] No managed backend PID found." -ForegroundColor Yellow
}

# 2. Stop Ollama
$OllamaStopScript = Join-Path $PSScriptRoot "stop-ollama.ps1"

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $OllamaStopScript

if ($LASTEXITCODE -ne 0) {
    throw "Ollama shutdown failed."
}

# 3. Keep PostgreSQL running
Write-Host "`nPostgreSQL remains running." -ForegroundColor Cyan
Write-Host "Docker volume and model are preserved." -ForegroundColor Cyan

Write-Host "`n[OK] NEXUS AI stopped successfully." -ForegroundColor Green