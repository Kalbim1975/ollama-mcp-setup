# install-design.ps1 - Skills de design + MCP Figma/Playwright pour Claude Code
# Usage: powershell -ExecutionPolicy Bypass -File install-design.ps1
#
# 1. Skills de design : Emil Kowalski, Impeccable, Taste Skill
# 2. MCP : Figma (lire les maquettes) + Playwright (voir et tester le site dans un navigateur)
# Tout est installe au niveau utilisateur : disponible dans tous vos projets.

$ok = 0
$ko = 0
function Report($label) {
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK - $label" -ForegroundColor Green
        $script:ok++
    } else {
        Write-Host "  ERREUR - $label (code $LASTEXITCODE)" -ForegroundColor Red
        $script:ko++
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Claude Code : skills de design + MCP" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Prerequis
Write-Host "[1/6] Verification des prerequis..." -ForegroundColor Yellow
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "  ERREUR: Node.js manquant -> https://nodejs.org/ (version 22+ conseillee)" -ForegroundColor Red
    exit 1
}
$nodeMajor = [int]((node --version).TrimStart('v').Split('.')[0])
Write-Host "  OK - Node.js $(node --version)" -ForegroundColor Green
if ($nodeMajor -lt 22) {
    Write-Host "  AVERT: Taste Skill demande Node 22+ pour ses scripts de verification" -ForegroundColor Yellow
}
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "  ERREUR: Claude Code manquant -> npm install -g @anthropic-ai/claude-code" -ForegroundColor Red
    exit 1
}
Write-Host "  OK - Claude Code disponible" -ForegroundColor Green

# 2. Skill Emil Kowalski (animations, design engineering)
Write-Host "[2/6] Skills Emil Kowalski..." -ForegroundColor Yellow
npx -y skills@latest add emilkowalski/skill -g -a claude-code -s '*' -y
Report "Skills Emil Kowalski (emil-design-eng, animate, review-animations...)"

# 3. Skill Impeccable (langage de design, audit, polish)
Write-Host "[3/6] Skill Impeccable..." -ForegroundColor Yellow
npx -y skills@latest add https://github.com/pbakaus/impeccable -g -a claude-code -s impeccable -y
Report "Skill Impeccable"

# 4. Taste Skill (anti-slop : direction artistique + verification navigateur)
Write-Host "[4/6] Taste Skill..." -ForegroundColor Yellow
npx -y skills@latest add https://github.com/Leonxlnx/taste-skill -g -a claude-code -s design-taste-frontend -y
Report "Taste Skill (design-taste-frontend)"

# 5. MCP Figma (serveur distant officiel, connexion OAuth au premier usage)
Write-Host "[5/6] MCP Figma..." -ForegroundColor Yellow
claude mcp remove figma --scope user 2>&1 | Out-Null
claude mcp add --scope user --transport http figma https://mcp.figma.com/mcp
Report "MCP Figma"

# 6. MCP Playwright (Claude ouvre le site, fait des captures, clique, verifie)
Write-Host "[6/6] MCP Playwright..." -ForegroundColor Yellow
claude mcp remove playwright --scope user 2>&1 | Out-Null
# Sous Windows natif, les serveurs MCP lances via npx ont besoin de "cmd /c".
# '--' est entre guillemets : sinon PowerShell le supprime et claude lit -y comme sa propre option.
claude mcp add --scope user playwright '--' cmd /c npx -y @playwright/mcp@latest
Report "MCP Playwright"

Write-Host ""
if ($ko -eq 0) {
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "  INSTALLATION TERMINEE ($ok/6)" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
} else {
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "  $ko etape(s) en erreur - voir ci-dessus" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
}
Write-Host ""
Write-Host "ETAPE SUIVANTE (une seule fois) :" -ForegroundColor Cyan
Write-Host "  1. Relancer Claude Code : claude"
Write-Host "  2. Taper /mcp > figma > Authenticate > Allow access"
Write-Host ""
Write-Host "UTILISATION :" -ForegroundColor Cyan
Write-Host "  /design-taste-frontend  Creer ou refaire une page avec une vraie direction artistique"
Write-Host "  /impeccable             Auditer et peaufiner une interface"
Write-Host "  /emil-design-eng        Animations et details d'interface"
Write-Host "  Figma     : collez un lien Figma -> 'Implemente cette maquette'"
Write-Host "  Playwright: 'Ouvre localhost:3000, fais une capture et corrige ce qui cloche'"
Write-Host ""
if ($ko -gt 0) { exit 1 }
