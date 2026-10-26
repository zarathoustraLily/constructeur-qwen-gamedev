"""Catalogue d'effets et de shaders du RAG (étape R1 du suivi) : une fiche et un exemple vérifié par effet.

`rag/effets/effets.toml` liste les effets ; `rag/effets/<id>/exemple/` contient leurs shaders et `exemple.gd`, qui
pilote l'effet par ses fonctions publiques, laisse le moteur dessiner, lit les pixels de l'image rendue et écrit
« EXEMPLE VERIFIE » si l'effet s'y voit comme prévu. Rendu fenêtre hors de l'écran, en Compatibilité, comme les
rendus des cours. Mécanique commune avec les morceaux de code : `catalogue.py`.

    python -m usine.rag.effets verifier [id …]
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

from usine.rag import catalogue
from usine.rag.catalogue import RE_FONCTION_PUBLIQUE, fonctions_publiques  # noqa: F401 (employés par les tests)

CATALOGUE = catalogue.Catalogue(
    nom="effets", genre="effet", rendu=True,
    rangement=("Dans un projet qui suit le plan, le shader va dans `6_assets/` (aucun code) et ses réglages (couleurs, "
               "durées) dans un `.tres` de `5_data/` (principe 2) ; la fonction qui le pilote va dans la présentation : "
               "le `_view.gd` de l'entité, ou `4_ui/` pour un effet d'écran (principe 1)."),
    titre_emploi="Le piloter depuis GDScript",
    verification="rendu en Compatibilité, fenêtre hors de l'écran, en lisant les pixels de l'image")
DOSSIER = CATALOGUE.dossier
MANIFESTE = CATALOGUE.chemin_manifeste


def manifeste() -> dict[str, dict[str, Any]]:
    return catalogue.manifeste(CATALOGUE)


def effets() -> list[str]:
    return sorted(manifeste())


def fiche(ident: str, entree: dict[str, Any], mesure: str, dossier: Path | None = None) -> str:
    return catalogue.fiche(CATALOGUE, ident, entree, mesure, dossier)


def verifier(ident: str, donnees: Path | None = None) -> dict[str, Any]:
    return catalogue.verifier(CATALOGUE, ident, manifeste()[ident], donnees)


def main(argv: list[str] | None = None) -> int:
    return catalogue.main(CATALOGUE, argv)


if __name__ == "__main__":
    sys.exit(main())
