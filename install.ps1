# install.ps1 - Ollama + VS Code + Claude Code
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Ollama + VS Code + Claude Code Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Node.js
Write-Host "[1/5] Verification Node.js..." -ForegroundColor Yellow
try {
    $v = node --version 2>&1
    Write-Host "  OK - Node.js $v" -ForegroundColor Green
} catch {
    Write-Host "  ERREUR: https://nodejs.org/" -ForegroundColor Red
    exit 1
}

# 2. Ollama
Write-Host "[2/5] Verification Ollama..." -ForegroundColor Yellow
try {
    $null = ollama list 2>&1
    Write-Host "  OK - Ollama disponible" -ForegroundColor Green
} catch {
    Write-Host "  ERREUR: https://ollama.com/download" -ForegroundColor Red
    exit 1
}

# 3. VS Code + Continue
Write-Host "[3/5] Installation Continue dans VS Code..." -ForegroundColor Yellow
try {
    $null = code --version 2>&1
    code --install-extension Continue.continue --force 2>&1 | Out-Null
    Write-Host "  OK - Continue installe dans VS Code" -ForegroundColor Green
} catch {
    Write-Host "  AVERT: VS Code non trouve -> https://code.visualstudio.com/" -ForegroundColor Yellow
}

# 4. Config Continue
Write-Host "[4/5] Configuration Continue + Ollama..." -ForegroundColor Yellow
$dir = "$env:USERPROFILE\.continue"
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$cfg = '{"models":[{"title":"qwen2.5:7b","provider":"ollama","model":"qwen2.5:7b","apiBase":"http://localhost:11434"},{"title":"llama3","provider":"ollama","model":"llama3:latest","apiBase":"http://localhost:11434"},{"title":"mistral","provider":"ollama","model":"mistral:latest","apiBase":"http://localhost:11434"}],"tabAutocompleteModel":{"title":"Autocomplete","provider":"ollama","model":"qwen2.5:7b","apiBase":"http://localhost:11434"},"allowAnonymousTelemetry":false}'
$cfg | Set-Content "$dir\config.json" -Encoding UTF8
Write-Host "  OK - Continue configure" -ForegroundColor Green

# 5. Claude Code MCP
Write-Host "[5/5] Configuration Claude Code MCP..." -ForegroundColor Yellow
$p = "$env:USERPROFILE\.claude.json"
if (Test-Path $p) { $c = Get-Content $p -Raw | ConvertFrom-Json } else { $c = [PSCustomObject]@{} }
if (-not ($c.PSObject.Properties.Name -contains 'mcpServers')) {
    $c | Add-Member -MemberType NoteProperty -Name 'mcpServers' -Value ([PSCustomObject]@{})
}
$m = [PSCustomObject]@{
    command = "npx"
    args = @("-y","ollama-mcp")
    env = [PSCustomObject]@{ OLLAMA_HOST = "http://127.0.0.1:11434" }
}
$c.mcpServers | Add-Member -MemberType NoteProperty -Name 'ollama-mcp' -Value $m -Force
$c | ConvertTo-Json -Depth 10 | Set-Content $p -Encoding UTF8
Write-Host "  OK - Claude Code configure" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  INSTALLATION TERMINEE !" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "VS CODE: Ouvrir VS Code > icone Continue > choisir modele Ollama" -ForegroundColor Cyan
Write-Host ""
Write-Host "CLAUDE CODE local:" -ForegroundColor Cyan
Write-Host '  $env:ANTHROPIC_BASE_URL="http://localhost:11434/v1"'
Write-Host '  $env:ANTHROPIC_API_KEY="ollama"'
Write-Host "  claude --model qwen2.5:7b"
Write-Host ""
