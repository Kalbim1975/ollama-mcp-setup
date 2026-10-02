"""Ajoute les equipes du dossier teams/ dans AutoGen Studio (deja demarre).

Usage : python import_teams.py [--url http://127.0.0.1:8080]
Les equipes deja presentes (meme nom) ne sont pas dupliquees.
"""

import argparse
import json
import time
import urllib.request
from pathlib import Path

TEAMS_DIR = Path(__file__).parent / "teams"
UTILISATEUR = "guestuser@gmail.com"  # utilisateur par defaut d'AutoGen Studio sans authentification


def appel(url: str, donnees: dict | None = None) -> dict:
    corps = json.dumps(donnees).encode() if donnees is not None else None
    requete = urllib.request.Request(url, data=corps, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(requete, timeout=10) as r:
        return json.load(r)


def attendre(url: str, secondes: int = 90) -> None:
    for _ in range(secondes):
        try:
            if appel(f"{url}/api/health").get("status"):
                return
        except OSError:
            pass
        time.sleep(1)
    raise SystemExit(f"AutoGen Studio ne repond pas sur {url}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default="http://127.0.0.1:8080")
    url = parser.parse_args().url.rstrip("/")

    attendre(url)
    existantes = appel(f"{url}/api/teams/?user_id={UTILISATEUR}").get("data", [])
    labels = {t["component"].get("label") for t in existantes}

    for chemin in sorted(TEAMS_DIR.glob("*.json")):
        composant = json.loads(chemin.read_text(encoding="utf-8"))
        if composant.get("label") in labels:
            print(f"Deja presente : {composant['label']}")
            continue
        appel(f"{url}/api/teams/", {"user_id": UTILISATEUR, "component": composant})
        print(f"Equipe ajoutee : {composant['label']}")


if __name__ == "__main__":
    main()
