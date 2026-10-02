# Demarre AutoGen Studio sur http://localhost:8080 et y ajoute les equipes
# Usage : powershell -ExecutionPolicy Bypass -File start.ps1 [-Port 8080]
param([int]$Port = 8080)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path ".venv")) {
    Write-Host "Lancez d'abord install.ps1" -ForegroundColor Red
    exit 1
}

# Ollama doit tourner en arriere-plan
try { Invoke-RestMethod "http://127.0.0.1:11434/api/tags" -TimeoutSec 3 | Out-Null }
catch {
    Write-Host "Demarrage d'Ollama..."
    Start-Process ollama -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 3
}

$url = "http://127.0.0.1:$Port"
$studio = Start-Process -FilePath ".\.venv\Scripts\autogenstudio.exe" `
    -ArgumentList "ui", "--port", $Port, "--appdir", ".\myapp" -NoNewWindow -PassThru

& .\.venv\Scripts\python.exe import_teams.py --url $url
Start-Process $url
Write-Host "AutoGen Studio est ouvert sur $url  (Ctrl+C pour arreter)" -ForegroundColor Green
Wait-Process -Id $studio.Id
