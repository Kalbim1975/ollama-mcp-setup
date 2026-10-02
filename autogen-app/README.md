# Assistant AutoGen Studio (Ollama, 100 % local)

Une application d'agents IA pour un cabinet de medecine integrative (traitement
des addictions par laser). Elle utilise [AutoGen Studio](https://microsoft.github.io/autogen/stable/user-guide/autogenstudio-user-guide/index.html)
et des modeles **Ollama** qui tournent sur votre ordinateur : vos textes ne sont
pas envoyes a un service d'IA en ligne.

## Les deux equipes d'agents

| Equipe | Agents | Ce qu'elle fait |
|--------|--------|-----------------|
| **Fiche patient (addictions & laser)** | chercheur -> redacteur -> relecteur | Le chercheur interroge PubMed, le redacteur ecrit une fiche en francais simple, le relecteur verifie (pas de promesse de guerison, avertissement present) puis ecrit `APPROUVE`. |
| **Compte rendu de seance** | secretaire_medical | Transforme des notes brutes de seance en compte rendu structure, sans rien inventer. |

> L'outil PubMed envoie seulement votre **sujet de recherche** (en anglais) a PubMed.
> N'y mettez jamais de nom ou de donnee de patient.

## Installation (Windows)

Prerequis : [Python 3.10+](https://www.python.org/downloads/) (cocher "Add to PATH") et [Ollama](https://ollama.com/download).

Dans PowerShell, depuis ce dossier :

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

Le script telecharge le modele `llama3.1`, cree un environnement Python (`.venv`),
installe AutoGen Studio et genere les equipes. Autre modele :
`install.ps1 -Model qwen2.5` (il doit gerer les outils : llama3.1, llama3.2, qwen2.5, mistral...).

## Utilisation

```powershell
powershell -ExecutionPolicy Bypass -File start.ps1
```

Le navigateur s'ouvre sur **http://localhost:8080** et les deux equipes sont ajoutees automatiquement.

1. Onglet **Playground** -> **New Session** -> choisissez une equipe.
2. Ecrivez votre demande, par exemple :
   - *Fiche patient* : `Auriculotherapie laser pour l'arret du tabac`
   - *Compte rendu* : `Mme D., tabac 15 cig/j -> 6 cig/j. 2e seance laser auriculaire, 20 min. Moins d'envies le matin. Revoir dans 15 jours.`
3. Onglet **Team Builder** : modifiez les consignes des agents, changez de modele, ajoutez des agents par glisser-deposer.

Sans interface, dans le terminal :

```powershell
.\.venv\Scripts\python.exe run_cli.py fiche_patient "Laser et sevrage alcoolique"
```

## Exemple OpenAI (optionnel)

`hello_openai.py` est un exemple minimal avec le modele `gpt-4o` d'OpenAI.
Il demande une cle API OpenAI payante, et **les textes partent sur les serveurs d'OpenAI** :
n'y mettez jamais de donnees de patients.

```powershell
$env:OPENAI_API_KEY = "sk-..."   # votre cle OpenAI
.\.venv\Scripts\python.exe hello_openai.py
```

## Fichiers

| Fichier | Role |
|---------|------|
| `build_teams.py` | Definit les agents et genere `teams/*.json` (modifiez les consignes ici) |
| `teams/*.json` | Equipes au format AutoGen Studio (importables aussi via la **Gallery**) |
| `import_teams.py` | Ajoute les equipes dans AutoGen Studio deja demarre |
| `run_cli.py` | Lance une equipe dans le terminal |
| `hello_openai.py` | Exemple minimal avec OpenAI gpt-4o (cle API requise) |
| `install.ps1` / `start.ps1` | Installation et demarrage sous Windows |

Les conversations sont enregistrees dans `myapp/` (sur votre ordinateur uniquement).

## Important

Les modeles locaux peuvent se tromper ou inventer des references. Relisez et
verifiez toujours le contenu (liens PubMed compris) avant de le remettre a un patient.
