# install.ps1 - MCP Ollama pour Claude Code
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1

Write-Host "" 
Write-Host "=== MCP Ollama pour Claude Code ===" -ForegroundColor Cyan
Write-Host ""

# 1. Verifier Node.js
Write-Host "[1/3] Verification de Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>&1
        Write-Host "  OK - Node.js $nodeVersion" -ForegroundColor Green
        } catch {
            Write-Host "  ERREUR: Installez Node.js depuis https://nodejs.org/" -ForegroundColor Red
                exit 1
                }

                # 2. Verifier Ollama
                Write-Host "[2/3] Verification d'Ollama..." -ForegroundColor Yellow
                try {
                    $null = ollama list 2>&1
                        Write-Host "  OK - Ollama disponible" -ForegroundColor Green
                        } catch {
                            Write-Host "  ERREUR: Installez Ollama depuis https://ollama.com/download" -ForegroundColor Red
                                exit 1
                                }

                                # 3. Configurer le MCP dans Claude Code
                                Write-Host "[3/3] Configuration du MCP..." -ForegroundColor Yellow

                                $claudeConfigPath = "$env:USERPROFILE\.claude.json"

                                if (Test-Path $claudeConfigPath) {
                                    $config = Get-Content $claudeConfigPath -Raw | ConvertFrom-Json
                                    } else {
                                        $config = [PSCustomObject]@{}
                                        }

                                        if (-not ($config.PSObject.Properties.Name -contains 'mcpServers')) {
                                            $config | Add-Member -MemberType NoteProperty -Name 'mcpServers' -Value ([PSCustomObject]@{})
                                            }

                                            $ollamaMcp = [PSCustomObject]@{
                                                command = "npx"
                                                    args    = @("-y", "ollama-mcp")
                                                        env     = [PSCustomObject]@{ OLLAMA_HOST = "http://127.0.0.1:11434" }
                                                        }

                                                        $config.mcpServers | Add-Member -MemberType NoteProperty -Name 'ollama-mcp' -Value $ollamaMcp -Force
                                                        $config | ConvertTo-Json -Depth 10 | Set-Content $claudeConfigPath -Encoding UTF8

                                                        Write-Host "  OK - Config sauvegardee dans $claudeConfigPath" -ForegroundColor Green
                                                        Write-Host ""
                                                        Write-Host "=== Installation terminee! ===" -ForegroundColor Green
                                                        Write-Host ""
                                                        Write-Host "Etapes suivantes:" -ForegroundColor Yellow
                                                        Write-Host "  1. Demarrer Ollama : ollama serve"
                                                        Write-Host "  2. Verifier le MCP : claude mcp list"
                                                        Write-Host "  3. Dans Claude Code: /mcp"
                                                        
