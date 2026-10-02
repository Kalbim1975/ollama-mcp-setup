"""Genere les fichiers d'equipe AutoGen Studio (dossier teams/).

Usage :
    python build_teams.py                  # modele par defaut : llama3.1
    python build_teams.py --model qwen2.5  # autre modele Ollama

Les fichiers JSON produits s'importent dans AutoGen Studio
(onglet "Team Builder" > "New Team" > coller le JSON, ou "Gallery" > "Import").
"""

import argparse
import json
from pathlib import Path

from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.conditions import MaxMessageTermination, TextMentionTermination
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_core.tools import FunctionTool
from autogen_ext.models.ollama import OllamaChatCompletionClient

TEAMS_DIR = Path(__file__).parent / "teams"

AVERTISSEMENT = (
    "Ce document est un support d'information. Il ne remplace pas une "
    "consultation ni l'avis d'un professionnel de sante."
)


def recherche_pubmed(requete: str, nombre: int = 5) -> str:
    """Cherche des articles sur PubMed et renvoie titres, revues, annees et liens."""
    import json as _json
    import urllib.parse
    import urllib.request

    base = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/"
    nombre = max(1, min(int(nombre), 10))
    params = urllib.parse.urlencode(
        {"db": "pubmed", "term": requete, "retmax": nombre, "retmode": "json", "sort": "relevance"}
    )
    try:
        with urllib.request.urlopen(f"{base}esearch.fcgi?{params}", timeout=20) as r:
            ids = _json.load(r)["esearchresult"].get("idlist", [])
        if not ids:
            return "Aucun article trouve pour cette recherche."

        params = urllib.parse.urlencode({"db": "pubmed", "id": ",".join(ids), "retmode": "json"})
        with urllib.request.urlopen(f"{base}esummary.fcgi?{params}", timeout=20) as r:
            resultats = _json.load(r)["result"]
    except Exception as erreur:
        return f"PubMed inaccessible ({erreur}). Signale-le sans inventer de resultats."

    lignes = []
    for pmid in ids:
        art = resultats.get(pmid, {})
        lignes.append(
            f"- {art.get('title', 'Sans titre')} ({art.get('source', '?')}, "
            f"{art.get('pubdate', '?')[:4]}) https://pubmed.ncbi.nlm.nih.gov/{pmid}/"
        )
    return "\n".join(lignes)


def client(model: str, host: str) -> OllamaChatCompletionClient:
    return OllamaChatCompletionClient(model=model, host=host)


def equipe_fiche_patient(model: str, host: str) -> RoundRobinGroupChat:
    """Recherche PubMed -> fiche patient en francais simple -> relecture."""
    outil_pubmed = FunctionTool(
        recherche_pubmed,
        description="Recherche d'articles scientifiques sur PubMed (requete en anglais).",
    )

    chercheur = AssistantAgent(
        name="chercheur",
        model_client=client(model, host),
        tools=[outil_pubmed],
        reflect_on_tool_use=True,
        description="Recherche les donnees scientifiques sur PubMed.",
        system_message=(
            "Tu es un assistant de recherche pour un infirmier praticien en medecine "
            "integrative qui traite les addictions (tabac, alcool, sucre...) par laser "
            "(auriculotherapie laser, photobiomodulation). "
            "Utilise l'outil recherche_pubmed avec une requete EN ANGLAIS, puis resume en "
            "francais ce que disent les etudes : niveau de preuve, resultats, limites. "
            "Cite les liens PubMed. N'invente jamais d'etude ni de chiffre."
        ),
    )

    redacteur = AssistantAgent(
        name="redacteur",
        model_client=client(model, host),
        description="Redige la fiche d'information patient.",
        system_message=(
            "Tu rediges des fiches d'information pour les patients, en francais simple "
            "et bienveillant (niveau college). A partir du resume du chercheur, ecris une "
            "fiche avec ces parties : 1) De quoi s'agit-il ? 2) Comment se deroule une "
            "seance ? 3) Ce que disent les etudes (honnetement, sans promesse de guerison) "
            "4) Conseils pour reussir son sevrage 5) Quand consulter un medecin. "
            f"Termine toujours par : \"{AVERTISSEMENT}\""
        ),
    )

    relecteur = AssistantAgent(
        name="relecteur",
        model_client=client(model, host),
        description="Verifie l'exactitude et la prudence de la fiche.",
        system_message=(
            "Tu es relecteur en sante. Verifie la fiche du redacteur : aucune promesse de "
            "guerison, pas d'affirmation non soutenue par les etudes citees, langage clair, "
            "avertissement present, orientation vers un medecin si besoin. "
            "Si des corrections sont necessaires, liste-les precisement. "
            "Si la fiche est correcte, recopie la version finale puis ecris APPROUVE "
            "sur la derniere ligne."
        ),
    )

    fin = TextMentionTermination("APPROUVE") | MaxMessageTermination(10)
    return RoundRobinGroupChat([chercheur, redacteur, relecteur], termination_condition=fin)


def equipe_notes_seance(model: str, host: str) -> RoundRobinGroupChat:
    """Notes brutes de seance -> compte rendu structure."""
    secretaire = AssistantAgent(
        name="secretaire_medical",
        model_client=client(model, host),
        description="Structure les notes de seance.",
        system_message=(
            "Tu transformes des notes brutes de seance (traitement des addictions par laser) "
            "en compte rendu structure, en francais :\n"
            "- Motif / addiction traitee\n- Consommation actuelle et evolution\n"
            "- Seance realisee (zones, protocole, duree) uniquement si mentionne\n"
            "- Ressenti du patient\n- Objectifs et prochain rendez-vous\n"
            "N'ajoute aucune information absente des notes : ecris 'non precise' si besoin. "
            "Termine ta reponse par TERMINE."
        ),
    )
    fin = TextMentionTermination("TERMINE") | MaxMessageTermination(3)
    return RoundRobinGroupChat([secretaire], termination_condition=fin)


EQUIPES = {
    "fiche_patient": (
        equipe_fiche_patient,
        "Fiche patient (addictions & laser)",
        "Chercheur PubMed -> redacteur -> relecteur : produit une fiche d'information patient.",
    ),
    "notes_seance": (
        equipe_notes_seance,
        "Compte rendu de seance",
        "Transforme des notes brutes de seance en compte rendu structure.",
    ),
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--model", default="llama3.1", help="modele Ollama gerant les outils (llama3.1, llama3.2, qwen2.5, mistral...)")
    parser.add_argument("--host", default="http://localhost:11434", help="adresse d'Ollama")
    args = parser.parse_args()

    TEAMS_DIR.mkdir(exist_ok=True)
    for nom, (fabrique, label, description) in EQUIPES.items():
        composant = fabrique(args.model, args.host).dump_component()
        composant.label, composant.description = label, description
        config = composant.model_dump(mode="json")
        chemin = TEAMS_DIR / f"{nom}.json"
        chemin.write_text(json.dumps(config, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"Equipe generee : {chemin}")


if __name__ == "__main__":
    main()
