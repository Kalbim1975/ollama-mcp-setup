# MCP Ollama pour Claude Code

Installe et configure automatiquement le serveur MCP [ollama-mcp](https://github.com/rawveg/ollama-mcp) pour connecter Ollama a Claude Code sur Windows.

## Installation en une commande

Ouvrez **PowerShell** et executez :

```powershell
irm https://github.com/Kalbim1975/ollama-mcp-setup/raw/refs/heads/main/install.ps1 | iex
```

Ou telechargez et executez le script manuellement :

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

## Prerequis

- [Node.js](https://nodejs.org/) v16+
- - [Ollama](https://ollama.com/download) installe et en cours d execution
  - - [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installe (`npm install -g @anthropic-ai/claude-code`)
   
    - ## Ce que fait le script
   
    - 1. Verifie que Node.js est installe
      2. 2. Verifie qu Ollama est disponible
         3. 3. Configure le MCP `ollama-mcp` dans `~/.claude.json`
           
            4. ## Configuration resultante
           
            5. ```json
               {
                 "mcpServers": {
                   "ollama-mcp": {
                     "command": "npx",
                     "args": ["-y", "ollama-mcp"],
                     "env": {
                       "OLLAMA_HOST": "http://127.0.0.1:11434"
                     }
                   }
                 }
               }
               ```

               ## Outils disponibles apres installation

               | Outil | Description |
               |-------|-------------|
               | `ollama_list` | Lister les modeles locaux |
               | `ollama_chat` | Chat avec un modele |
               | `ollama_pull` | Telecharger un modele |
               | `ollama_generate` | Generer du texte |
               | `ollama_embed` | Generer des embeddings |
               | `ollama_ps` | Lister les modeles en cours |

               ## Verification

               ```powershell
               # Demarrer Ollama
               ollama serve

               # Verifier le MCP dans Claude Code
               claude mcp list

               # Dans une session Claude Code, taper:
               /mcp
               ```
