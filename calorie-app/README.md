# 🥗 CaloriePhoto — Calcul de calories à partir d'une photo

Application mobile (PWA) qui estime les calories d'un repas à partir d'une simple photo,
grâce à un modèle de vision **Ollama** tournant sur votre ordinateur. Aucune donnée
n'est envoyée sur Internet : tout reste sur votre réseau local.

## Fonctionnalités

- 📷 **Photo du repas** avec l'appareil photo du téléphone
- 🤖 **Analyse par IA locale** (llava, moondream, llama3.2-vision…) : aliments, portions, calories
- ✏️ **Calories modifiables** avant validation
- 🧮 **Macros** : protéines, glucides, lipides
- 📒 **Journal quotidien** avec objectif calorique et barre de progression
- 📲 **Installable** sur l'écran d'accueil (Android et iPhone), fonctionne hors ligne (interface)

## Prérequis

1. [Ollama](https://ollama.com/download) installé sur votre ordinateur
2. Un modèle de vision téléchargé :

   ```powershell
   ollama pull llava
   ```

3. Le téléphone et l'ordinateur sur le **même réseau Wi-Fi**

## Démarrage

### 1. Lancer Ollama en acceptant le réseau local

Sous **Windows (PowerShell)** :

```powershell
$env:OLLAMA_HOST = "0.0.0.0"
$env:OLLAMA_ORIGINS = "*"
ollama serve
```

Sous **macOS / Linux** :

```bash
OLLAMA_HOST=0.0.0.0 OLLAMA_ORIGINS=* ollama serve
```

> `OLLAMA_ORIGINS=*` autorise le navigateur du téléphone à interroger Ollama (CORS).
> À réserver à votre réseau domestique.

### 2. Servir l'application

Depuis le dossier `calorie-app` :

```powershell
npx serve .
```

ou avec Python :

```powershell
python -m http.server 8080
```

### 3. Ouvrir sur le téléphone

1. Trouvez l'adresse IP de votre ordinateur (`ipconfig` sous Windows, ex. `192.168.1.10`)
2. Sur le téléphone, ouvrez `http://192.168.1.10:8080`
3. Dans **⚙️ Réglages**, indiquez l'adresse du serveur Ollama : `http://192.168.1.10:11434`
   et choisissez le modèle de vision
4. (Optionnel) « Ajouter à l'écran d'accueil » pour l'installer comme une vraie application

### 4. Utiliser

Appuyez sur **« Photographier mon repas »**, laissez l'IA analyser, ajustez les calories
si besoin, puis **Ajouter** au journal du jour. L'objectif quotidien se règle dans ⚙️ Réglages.

## Remarques

- Les estimations d'un modèle de vision local sont **indicatives** : vérifiez et corrigez
  les valeurs avant de les ajouter au journal.
- Le journal est stocké dans le navigateur du téléphone (localStorage), un jour par entrée.
- Sur iPhone, l'accès à l'appareil photo depuis une page `http://` du réseau local fonctionne
  via le sélecteur de fichiers ; pour une expérience complète en HTTPS, vous pouvez servir
  l'application derrière un proxy TLS local.
