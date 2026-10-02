# Installe l'application AutoGen Studio + Ollama (Windows)
# Usage : powershell -ExecutionPolicy Bypass -File install.ps1 [-Model llama3.1]
param([string]$Model = "llama3.1")

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "=== Installation de l'assistant AutoGen (Ollama) ===" -ForegroundColor Cyan

# 1. Python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Python est introuvable. Installez Python 3.10+ : https://www.python.org/downloads/ (cochez 'Add to PATH')" -ForegroundColor Red
    exit 1
}
python -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Python 3.10 ou plus recent est requis." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Python trouve" -ForegroundColor Green

# 2. Ollama + modele
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "Ollama est introuvable. Installez-le : https://ollama.com/download" -ForegroundColor Red
    exit 1
}
Write-Host "Telechargement du modele $Model (peut prendre plusieurs minutes)..."
ollama pull $Model
Write-Host "[OK] Modele $Model pret" -ForegroundColor Green

# 3. Environnement Python isole
if (-not (Test-Path ".venv")) { python -m venv .venv }
& .\.venv\Scripts\python.exe -m pip install --upgrade pip --quiet
& .\.venv\Scripts\python.exe -m pip install -r requirements.txt
Write-Host "[OK] AutoGen Studio installe" -ForegroundColor Green

# 4. Equipes d'agents
& .\.venv\Scripts\python.exe build_teams.py --model $Model
Write-Host ""
Write-Host "Installation terminee. Lancez l'application avec :" -ForegroundColor Cyan
Write-Host "  powershell -ExecutionPolicy Bypass -File start.ps1"
