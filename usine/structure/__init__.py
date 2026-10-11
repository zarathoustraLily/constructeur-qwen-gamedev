"""Juge de structure (béquille, point 2) : un projet rangé selon son plan d'organisation.

Déterministe (règle 2). On lit quels fichiers chaque script, scène ou ressource charge
(chemins res://, class_name du projet, autoloads) et on vérifie les règles « qui connaît qui »
de godot/socle_jeu/ORGANISATION.md, plus quelques règles de rangement (noms, emplacement).

    python -m usine.structure verifier <projet>
"""

from usine.structure.regles import DOSSIERS, verifier_projet
from usine.structure.session import verifier_session

__all__ = ["DOSSIERS", "verifier_projet", "verifier_session"]
