"""Lance une equipe directement dans le terminal, sans l'interface web.

Exemples :
    python run_cli.py fiche_patient "Auriculotherapie laser pour l'arret du tabac"
    python run_cli.py notes_seance "Mme D, tabac 15 cig/j -> 6. 2e seance laser auriculaire..."
"""

import argparse
import asyncio
import json
from pathlib import Path

from autogen_agentchat.base import Team
from autogen_agentchat.ui import Console

TEAMS_DIR = Path(__file__).parent / "teams"


async def main() -> None:
    equipes = sorted(p.stem for p in TEAMS_DIR.glob("*.json"))
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("equipe", choices=equipes)
    parser.add_argument("demande", help="votre sujet ou vos notes, entre guillemets")
    args = parser.parse_args()

    config = json.loads((TEAMS_DIR / f"{args.equipe}.json").read_text(encoding="utf-8"))
    team = Team.load_component(config)
    await Console(team.run_stream(task=args.demande))


if __name__ == "__main__":
    asyncio.run(main())
