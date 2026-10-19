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

## Skills de design + MCP Figma / Playwright

Pour que les sites generes par Claude Code ne ressemblent plus a des templates IA, `install-design.ps1` installe :

| Element | Type | Role |
|---------|------|------|
| [Emil Kowalski](https://emilkowal.ski/skill) | Skills | Animations et details d'interface (`/emil-design-eng`, `/animate`, `/review-animations`...) |
| [Impeccable](https://github.com/pbakaus/impeccable) | Skill | Langage de design, audit et polish d'interface (`/impeccable`) |
| [Taste Skill](https://github.com/Leonxlnx/taste-skill) | Skill | Direction artistique anti-slop, verifiee dans un vrai navigateur (`/design-taste-frontend`) |
| [Figma](https://developers.figma.com/docs/figma-mcp-server/) | MCP | Lire vos maquettes Figma et les implementer |
| [Playwright](https://github.com/microsoft/playwright-mcp) | MCP | Ouvrir le site, faire des captures, cliquer et verifier le rendu |

```powershell
irm https://github.com/Kalbim1975/ollama-mcp-setup/raw/refs/heads/main/install-design.ps1 | iex
```

Prerequis : Node.js 22+, Claude Code, et Chrome/Edge (pour Taste Skill). Tout est installe au niveau utilisateur (disponible dans tous les projets).

Apres l'installation, une seule fois : relancer `claude`, taper `/mcp` > **figma** > **Authenticate** > **Allow access**.

## Application AutoGen Studio

Le dossier [`autogen-app/`](autogen-app/) contient une application d'agents IA (AutoGen Studio + Ollama, 100 % locale) : fiches d'information patient a partir de PubMed et comptes rendus de seance. Voir [autogen-app/README.md](autogen-app/README.md).
