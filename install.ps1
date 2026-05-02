# install.ps1 - Ollama + VS Code (Continue) + Claude Code
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Ollama + VS Code + Claude Code Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Node.js ──────────────────────────────────────────────
Write-Host "[1/5] Verification de Node.js..." -ForegroundColor Yellow
try {
    $v = node --version 2>&1
        Write-Host "  OK - Node.js $v" -ForegroundColor Green
        } catch {
            Write-Host "  ERREUR: Installez Node.js -> https://nodejs.org/" -ForegroundColor Red
                exit 1
                }

                # ── 2. Ollama ───────────────────────────────────────────────
                Write-Host "[2/5] Verification d'Ollama..." -ForegroundColor Yellow
                try {
                    $null = ollama list 2>&1
                        Write-Host "  OK - Ollama disponible" -ForegroundColor Green
                        } catch {
                            Write-Host "  ERREUR: Installez Ollama -> https://ollama.com/download" -ForegroundColor Red
                                exit 1
                                }

                                # ── 3. VS Code + extension Continue ─────────────────────────
                                Write-Host "[3/5] Installation de l'extension Continue dans VS Code..." -ForegroundColor Yellow
                                try {
                                    $null = code --version 2>&1
                                        code --install-extension Continue.continue --force 2>&1 | Out-Null
                                            Write-Host "  OK - Extension Continue installee dans VS Code" -ForegroundColor Green
                                            } catch {
                                                Write-Host "  AVERTISSEMENT: VS Code introuvable, ignoré" -ForegroundColor Yellow
                                                    Write-Host "  Installez VS Code -> https://code.visualstudio.com/" -ForegroundColor Yellow
                                                    }

                                                    # ── 4. Config Continue pour Ollama ──────────────────────────
                                                    Write-Host "[4/5] Configuration de Continue pour Ollama..." -ForegroundColor Yellow

                                                    $continueDir = "$env:USERPROFILE\.continue"
                                                    if (-not (Test-Path $continueDir)) {
                                                        New-Item -ItemType Directory -Path $continueDir -Force | Out-Null
                                                        }

                                                        $continueConfig = @'
                                                        {
                                                          "models": [
                                                              {
                                                                    "title": "Ollama - qwen2.5:7b",
                                                                          "provider": "ollama",
                                                                                "model": "qwen2.5:7b",
                                                                                      "apiBase": "http://localhost:11434"
                                                                                          },
                                                                                              {
                                                                                                    "title": "Ollama - llama3",
                                                                                                          "provider": "ollama",
                                                                                                                "model": "llama3:latest",
                                                                                                                      "apiBase": "http://localhost:11434"
                                                                                                                          },
                                                                                                                              {
                                                                                                                                    "title": "Ollama - mistral",
                                                                                                                                          "provider": "ollama",
                                                                                                                                                "model": "mistral:latest",
                                                                                                                                                      "apiBase": "http://localhost:11434"
                                                                                                                                                          }
                                                                                                                                                            ],
                                                                                                                                                              "tabAutocompleteModel": {
                                                                                                                                                                  "title": "Ollama Autocomplete",
                                                                                                                                                                      "provider": "ollama",
                                                                                                                                                                          "model": "qwen2.5:7b",
                                                                                                                                                                              "apiBase": "http://localhost:11434"
                                                                                                                                                                                },
                                                                                                                                                                                  "allowAnonymousTelemetry": false
                                                                                                                                                                                  }
                                                                                                                                                                                  '@
                                                                                                                                                                                  
                                                                                                                                                                                  $continueConfig | Set-Content "$continueDir\config.json" -Encoding UTF8
                                                                                                                                                                                  Write-Host "  OK - Continue configure avec tes modeles Ollama" -ForegroundColor Green
                                                                                                                                                                                  
                                                                                                                                                                                  # ── 5. Config Claude Code pour Ollama local ──────────────────
                                                                                                                                                                                  Write-Host "[5/5] Configuration de Claude Code pour Ollama local..." -ForegroundColor Yellow
                                                                                                                                                                                  
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
                                                                                                                                                                                                          Write-Host "  OK - Claude Code configure avec MCP Ollama" -ForegroundColor Green
                                                                                                                                                                                                          
                                                                                                                                                                                                          # ── Résumé ───────────────────────────────────────────────────
                                                                                                                                                                                                          Write-Host ""
                                                                                                                                                                                                          Write-Host "==========================================" -ForegroundColor Green
                                                                                                                                                                                                          Write-Host "  INSTALLATION TERMINEE !" -ForegroundColor Green
                                                                                                                                                                                                          Write-Host "==========================================" -ForegroundColor Green
                                                                                                                                                                                                          Write-Host ""
                                                                                                                                                                                                          Write-Host "PROCHAINES ETAPES:" -ForegroundColor Cyan
                                                                                                                                                                                                          Write-Host ""
                                                                                                                                                                                                          Write-Host "  VS CODE + CONTINUE (100% local):" -ForegroundColor Yellow
                                                                                                                                                                                                          Write-Host "    1. Ouvre VS Code"
                                                                                                                                                                                                          Write-Host "    2. Clique sur l'icone Continue (barre laterale gauche)"
                                                                                                                                                                                                          Write-Host "    3. Selectionne ton modele Ollama et commence a coder !"
                                                                                                                                                                                                          Write-Host ""
                                                                                                                                                                                                          Write-Host "  CLAUDE CODE + OLLAMA (local):" -ForegroundColor Yellow
                                                                                                                                                                                                          Write-Host "    1. Dans PowerShell:"
                                                                                                                                                                                                          Write-Host "       `$env:ANTHROPIC_BASE_URL='http://localhost:11434/v1'"
                                                                                                                                                                                                          Write-Host "       `$env:ANTHROPIC_API_KEY='ollama'"
                                                                                                                                                                                                          Write-Host "       claude --model qwen2.5:7b"
                                                                                                                                                                                                          Write-Host ""
                                                                                                                                                                                                          Write-Host "  MODELE RECOMMANDE POUR LE CODE:" -ForegroundColor Yellow
                                                                                                                                                                                                          Write-Host "    ollama run qwen2.5:7b"
                                                                                                                                                                                                          Write-Host ""
