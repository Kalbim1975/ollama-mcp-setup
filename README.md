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

## Application AutoGen Studio

Le dossier [`autogen-app/`](autogen-app/) contient une application d'agents IA (AutoGen Studio + Ollama, 100 % locale) : fiches d'information patient a partir de PubMed et comptes rendus de seance. Voir [autogen-app/README.md](autogen-app/README.md).

## Skills d'agent (find-skills) et audit de sécurité

Le skill [`find-skills`](https://github.com/vercel-labs/skills) (Vercel Labs) est installé dans `.claude/skills/find-skills/` : il permet à Claude Code de rechercher et proposer d'autres skills (`npx skills find <mot-clé>`). La provenance et l'empreinte SHA-256 sont tracées dans `skills-lock.json`.

Un skill s'exécute avec toutes les permissions de l'agent : chaque skill est donc audité.

```bash
# Auditer les skills installés (échoue sur toute alerte HAUTE)
node scripts/audit-skills.mjs

# Mode strict (échoue aussi sur les alertes MOYENNES)
node scripts/audit-skills.mjs --strict

# Auditer un skill AVANT de l'installer
git clone --depth 1 https://github.com/<owner>/<repo> /tmp/skill-a-verifier
node scripts/audit-skills.mjs /tmp/skill-a-verifier/skills/<nom>
```

L'audit détecte : exécution de code distant (`curl | sh`, `irm | iex`), contenu encodé, lecture de secrets (`.ssh`, `.env`, `~/.claude.json`), exfiltration (POST, webhooks, ngrok…), injection de consignes, contournement des permissions, persistance, commandes destructrices, caractères invisibles, commentaires HTML cachés, scripts/binaires embarqués, et toute modification du skill depuis `skills-lock.json`.

Il tourne aussi automatiquement sur GitHub Actions (à chaque PR touchant les skills et chaque lundi). Les règles d'installation imposées à Claude sont dans [`CLAUDE.md`](CLAUDE.md).

**Installer un nouveau skill (procédure sûre) :**

```bash
npx skills add <owner/repo> --skill <nom> --agent claude-code --copy   # sans -g ni -y
node scripts/audit-skills.mjs
```

> Alerte connue : `find-skills` suggère `npx skills add ... -g -y` (installation globale sans confirmation). C'est signalé en 🟠 MOYENNE ; `CLAUDE.md` interdit à Claude d'appliquer cette consigne sans votre accord.
