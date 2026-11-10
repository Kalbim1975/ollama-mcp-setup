#!/usr/bin/env node
// Audit de sécurité des skills d'agent installés dans ce dépôt.
//
// Usage :
//   node scripts/audit-skills.mjs            # audite .claude/skills et .agents/skills
//   node scripts/audit-skills.mjs --strict   # échoue aussi sur les alertes MOYENNES
//   node scripts/audit-skills.mjs <dossier>  # audite un skill avant installation
//
// Code de sortie : 0 = OK, 1 = alerte(s) bloquante(s), 2 = erreur d'exécution.
// Aucune dépendance : Node.js 18+ suffit.

import { createHash } from "node:crypto";
import { existsSync } from "node:fs";
import { readdir, readFile, stat } from "node:fs/promises";
import { join, relative, extname, resolve } from "node:path";

const ROOT = process.cwd();
const args = process.argv.slice(2);
const STRICT = args.includes("--strict");
const targets = args.filter((a) => !a.startsWith("--"));

// Domaines considérés comme normaux dans un skill (documentation, sources connues).
const ALLOWED_DOMAINS = [
  "skills.sh",
  "github.com",
  "raw.githubusercontent.com",
  "docs.anthropic.com",
  "code.claude.com",
  "anthropic.com",
  "vercel.com",
  "nodejs.org",
  "npmjs.com",
  "ollama.com",
  "localhost",
  "127.0.0.1",
];

// Extensions exécutables ou binaires : un skill « texte » ne devrait pas en avoir.
const SCRIPT_EXT = new Set([
  ".sh", ".bash", ".zsh", ".ps1", ".psm1", ".bat", ".cmd", ".vbs",
  ".py", ".js", ".mjs", ".cjs", ".ts", ".rb", ".pl", ".php",
]);
const BINARY_EXT = new Set([
  ".exe", ".dll", ".so", ".dylib", ".bin", ".msi", ".scr", ".jar", ".zip", ".tar", ".gz", ".7z",
]);

// [gravité, identifiant, description, regex]
const RULES = [
  // --- Exécution de code distant ---
  ["HAUTE", "remote-pipe-shell", "Téléchargement exécuté directement (curl/wget | sh)",
    /\b(curl|wget)\b[^\n|]*\|\s*(sudo\s+)?(ba|z)?sh\b/i],
  ["HAUTE", "powershell-iex", "PowerShell : téléchargement + Invoke-Expression",
    /\b(iwr|irm|Invoke-WebRequest|Invoke-RestMethod|DownloadString)\b[^\n]*\|\s*(iex|Invoke-Expression)\b/i],
  ["HAUTE", "encoded-exec", "Exécution de contenu encodé (base64/-EncodedCommand)",
    /(base64\s+(-d|--decode)[^\n]*\|\s*(ba)?sh|-EncodedCommand|FromBase64String|\batob\s*\()/i],
  ["MOYENNE", "eval", "Appel à eval/exec dynamique",
    /\b(eval\s*\(|exec\s*\(|new Function\s*\(|child_process|subprocess\.(Popen|call|run)|os\.system)/],

  // --- Accès aux secrets ---
  ["HAUTE", "secret-files", "Lecture de fichiers sensibles (clés SSH, .env, identifiants)",
    /(~|\$HOME|%USERPROFILE%)?[\\/]?\.(ssh|aws|gnupg|docker|kube)[\\/]|id_rsa|id_ed25519|\.netrc|\.npmrc|\.git-credentials|credentials\.json|\bcat\s+[^\n]*\.env\b/i],
  ["HAUTE", "claude-config", "Accès à la configuration/aux identifiants de Claude",
    /\.claude\.json|\.claude[\\/](settings|credentials)|ANTHROPIC_API_KEY|CLAUDE_CODE_OAUTH/i],
  ["MOYENNE", "secret-env", "Référence à des variables de secrets",
    /\b(GITHUB_TOKEN|GH_TOKEN|NPM_TOKEN|AWS_SECRET_ACCESS_KEY|OPENAI_API_KEY|API_KEY|SECRET_KEY|PASSWORD)\b/],

  // --- Exfiltration ---
  ["HAUTE", "exfil-post", "Envoi de données vers l'extérieur (curl -d / POST / webhook)",
    /\b(curl|wget|Invoke-WebRequest|Invoke-RestMethod)\b[^\n]*(\s-d\s|--data|-F\s|--upload-file|-Method\s+Post|-X\s*POST)/i],
  ["HAUTE", "exfil-service", "Service d'exfiltration connu (webhook, pastebin, ngrok…)",
    /(webhook\.site|requestbin|pipedream\.net|ngrok\.(io|app)|pastebin\.com|transfer\.sh|discord(app)?\.com\/api\/webhooks|api\.telegram\.org\/bot)/i],

  // --- Injection de consignes ---
  ["HAUTE", "prompt-injection", "Tentative de contourner les consignes de l'agent",
    /(ignore|disregard|oublie|ignorez?)\s+(all\s+|toutes?\s+les\s+)?(previous|prior|above|précédentes?)\s+(instructions|consignes)|do not (tell|inform|mention to) the user|ne (le )?dis pas à l'utilisateur|without (asking|telling) the user|sans (demander|prévenir)/i],
  ["HAUTE", "permission-bypass", "Contournement des permissions de l'agent",
    /--dangerously-skip-permissions|bypassPermissions|dangerouslyDisableSandbox|"defaultMode"\s*:\s*"(bypassPermissions|acceptEdits)"/i],
  ["MOYENNE", "auto-confirm", "Installation/exécution sans confirmation (-y / --yes / -g)",
    /\b(npx|npm|pip|skills)\b[^\n]*\s(-y|--yes)\b|\bskills\s+add\b[^\n]*\s(-g|--global)\b/],

  // --- Persistance / destruction ---
  ["HAUTE", "persistence", "Mécanisme de persistance (cron, démarrage, registre, profil shell)",
    /\bcrontab\b|schtasks|CurrentVersion\\Run|systemctl\s+enable|launchctl\s+load|>>\s*~?\/?\.?(bashrc|zshrc|profile)|\$PROFILE/i],
  ["HAUTE", "destructive", "Commande destructrice",
    /\brm\s+-[a-z]*r[a-z]*f?\s+(\/|~|\$HOME|\*)|Remove-Item[^\n]*-Recurse[^\n]*(C:\\|\$env:USERPROFILE|~)|\bformat\s+[a-z]:|mkfs\.|git\s+push\s+[^\n]*--force/i],
  ["MOYENNE", "privilege", "Élévation de privilèges",
    /\bsudo\b|\brunas\b|-Verb\s+RunAs|Set-ExecutionPolicy\s+(Bypass|Unrestricted)/i],
  ["MOYENNE", "hooks-settings", "Modification des hooks/paramètres de l'agent",
    /\.claude[\\/]settings(\.local)?\.json|"hooks"\s*:|SessionStart|PreToolUse|PostToolUse/],
];

// Caractères invisibles ou de contrôle de direction (masquage de texte).
const HIDDEN_CHARS = /[\u200B-\u200F\u202A-\u202E\u2060-\u2064\u2066-\u2069\uFEFF\u00AD]/;
const HTML_COMMENT = /<!--[\s\S]*?-->/;
const URL_RE = /https?:\/\/([a-z0-9.-]+)/gi;

const findings = [];
const add = (sev, skill, file, line, rule, msg, excerpt = "") =>
  findings.push({ sev, skill, file, line, rule, msg, excerpt: excerpt.trim().slice(0, 140) });

async function collectFiles(baseDir, currentDir = baseDir, out = []) {
  for (const entry of await readdir(currentDir, { withFileTypes: true })) {
    const full = join(currentDir, entry.name);
    if (entry.isSymbolicLink()) {
      out.push({ rel: relative(baseDir, full).split("\\").join("/"), full, symlink: true });
    } else if (entry.isDirectory()) {
      if (entry.name === ".git" || entry.name === "node_modules") continue;
      await collectFiles(baseDir, full, out);
    } else if (entry.isFile()) {
      out.push({ rel: relative(baseDir, full).split("\\").join("/"), full, content: await readFile(full) });
    }
  }
  return out;
}

// Même algorithme que le CLI `skills` (computeSkillFolderHash) pour vérifier skills-lock.json.
function folderHash(files) {
  const h = createHash("sha256");
  for (const f of [...files].filter((f) => !f.symlink).sort((a, b) => a.rel.localeCompare(b.rel))) {
    h.update(f.rel);
    h.update(f.content);
  }
  return h.digest("hex");
}

function domainAllowed(host) {
  host = host.toLowerCase();
  return ALLOWED_DOMAINS.some((d) => host === d || host.endsWith("." + d));
}

async function auditSkill(name, dir, lock) {
  const files = await collectFiles(dir);
  if (!files.some((f) => f.rel === "SKILL.md")) add("MOYENNE", name, "-", 0, "no-skill-md", "Pas de SKILL.md à la racine du skill");

  for (const f of files) {
    if (f.symlink) { add("MOYENNE", name, f.rel, 0, "symlink", "Lien symbolique (peut pointer hors du dépôt)"); continue; }
    const ext = extname(f.rel).toLowerCase();
    if (BINARY_EXT.has(ext) || f.content.includes(0)) { add("HAUTE", name, f.rel, 0, "binary", "Fichier binaire/archive dans un skill"); continue; }
    if (SCRIPT_EXT.has(ext)) add("MOYENNE", name, f.rel, 0, "script-file", "Script exécutable embarqué : à relire intégralement");
    if (f.content.length > 200_000) add("INFO", name, f.rel, 0, "large-file", `Fichier volumineux (${f.content.length} octets)`);

    const text = f.content.toString("utf8");
    text.split(/\r?\n/).forEach((line, i) => {
      for (const [sev, id, msg, re] of RULES) if (re.test(line)) add(sev, name, f.rel, i + 1, id, msg, line);
      if (HIDDEN_CHARS.test(line)) add("HAUTE", name, f.rel, i + 1, "hidden-chars", "Caractères invisibles/bidirectionnels (texte masqué)", JSON.stringify(line));
      for (const m of line.matchAll(URL_RE)) {
        if (!domainAllowed(m[1])) add("INFO", name, f.rel, i + 1, "external-url", `URL vers un domaine non répertorié : ${m[1]}`, line);
      }
    });
    if (ext === ".md" && HTML_COMMENT.test(text)) add("MOYENNE", name, f.rel, 0, "html-comment", "Commentaire HTML (invisible au rendu, lu par l'agent)");
  }

  if (lock) {
    const entry = lock.skills?.[name];
    if (!entry) add("MOYENNE", name, "-", 0, "not-locked", "Skill absent de skills-lock.json (origine non tracée)");
    else if (entry.computedHash && entry.computedHash !== folderHash(files))
      add("HAUTE", name, "-", 0, "hash-mismatch", "Contenu modifié depuis skills-lock.json (hash différent)");
  }
  return files.length;
}

async function main() {
  let lock = null;
  if (existsSync(join(ROOT, "skills-lock.json"))) lock = JSON.parse(await readFile(join(ROOT, "skills-lock.json"), "utf8"));

  const skillDirs = [];
  if (targets.length) {
    for (const t of targets) skillDirs.push({ name: t, dir: resolve(t), lock: null });
  } else {
    for (const base of [".claude/skills", ".agents/skills"]) {
      const abs = join(ROOT, base);
      if (!existsSync(abs)) continue;
      for (const e of await readdir(abs, { withFileTypes: true })) {
        if (e.isDirectory() || e.isSymbolicLink()) skillDirs.push({ name: e.name, dir: join(abs, e.name), lock, base });
      }
    }
    if (lock) for (const n of Object.keys(lock.skills || {}))
      if (!skillDirs.some((s) => s.name === n)) add("MOYENNE", n, "-", 0, "missing", "Déclaré dans skills-lock.json mais introuvable");
  }

  if (!skillDirs.length) { console.log("Aucun skill à auditer."); return 0; }

  console.log(`Audit de sécurité des skills — ${new Date().toISOString()}\n`);
  for (const s of skillDirs) {
    if (!(await stat(s.dir)).isDirectory()) continue;
    const n = await auditSkill(s.name, s.dir, s.lock);
    console.log(`• ${s.base ? s.base + "/" : ""}${s.name} : ${n} fichier(s) analysé(s)`);
  }

  const order = { HAUTE: 0, MOYENNE: 1, INFO: 2 };
  findings.sort((a, b) => order[a.sev] - order[b.sev]);
  const count = (sev) => findings.filter((f) => f.sev === sev).length;

  console.log("");
  if (!findings.length) console.log("✅ Aucune alerte.");
  for (const f of findings) {
    const icon = f.sev === "HAUTE" ? "🔴" : f.sev === "MOYENNE" ? "🟠" : "🔵";
    console.log(`${icon} [${f.sev}] ${f.skill}/${f.file}${f.line ? ":" + f.line : ""} — ${f.msg} (${f.rule})`);
    if (f.excerpt) console.log(`     ↳ ${f.excerpt}`);
  }
  console.log(`\nRésumé : ${count("HAUTE")} haute(s), ${count("MOYENNE")} moyenne(s), ${count("INFO")} info(s).`);

  const blocking = count("HAUTE") + (STRICT ? count("MOYENNE") : 0);
  if (blocking) console.log(`❌ Audit échoué${STRICT ? " (mode strict)" : ""} : relisez les alertes avant d'utiliser ces skills.`);
  return blocking ? 1 : 0;
}

main().then((code) => process.exit(code)).catch((err) => { console.error("Erreur d'audit :", err); process.exit(2); });
