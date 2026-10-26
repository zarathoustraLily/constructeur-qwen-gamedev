"""Catalogue de morceaux de code du RAG (étape R2 du suivi) : une fiche et un exemple vérifié par savoir-faire.

Machines à états, caméras, inventaires, interface, procédural, IA, collisions, manette. `rag/morceaux/morceaux.toml`
liste les morceaux, avec où les ranger dans le plan et les fichiers du socle qu'ils emploient (copiés à leur place
dans le projet de vérification) ; `rag/morceaux/<id>/exemple/` contient le code du morceau et `exemple.gd`, qui
l'emploie, mesure son comportement et écrit « EXEMPLE VERIFIE » s'il est conforme. Sans fenêtre, sauf pour un
morceau marqué `rendu = true`. Mécanique commune avec les effets : `catalogue.py`.

    python -m usine.rag.morceaux verifier [id …]
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

from usine.rag import catalogue

CATALOGUE = catalogue.Catalogue(
    nom="morceaux", genre="morceau", rendu=False,
    rangement="Dans un projet qui suit le plan : voir le tableau des dossiers du plan.",
    titre_emploi="L'employer depuis GDScript",
    verification="sans fenêtre, en mesurant son comportement",
    code_a_la_racine=True)
DOSSIER = CATALOGUE.dossier


def manifeste() -> dict[str, dict[str, Any]]:
    return catalogue.manifeste(CATALOGUE)


def morceaux() -> list[str]:
    return sorted(manifeste())


def fiche(ident: str, entree: dict[str, Any], mesure: str, dossier: Path | None = None) -> str:
    return catalogue.fiche(CATALOGUE, ident, entree, mesure, dossier)


def main(argv: list[str] | None = None) -> int:
    return catalogue.main(CATALOGUE, argv)


if __name__ == "__main__":
    sys.exit(main())
