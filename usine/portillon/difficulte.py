"""Filtre de difficulté (prévu pour la boucle RFT, session 5).

Le modèle courant tente chaque tâche `essais` fois (8 par défaut) ; on garde les tâches qu'il
réussit entre `mini` et `maxi` fois (1 à 6) : ni acquises, ni hors de portée. Les réussites
viennent du juge, jamais d'un LLM.
"""

from __future__ import annotations

from typing import Iterable


def classer(reussites: Iterable[bool], essais: int = 8, mini: int = 1, maxi: int = 6) -> str:
    """« garder », « trop_facile », « trop_difficile » ou « essais_incomplets »."""
    liste = list(reussites)
    if len(liste) != essais:
        return "essais_incomplets"
    n = sum(bool(r) for r in liste)
    if n < mini:
        return "trop_difficile"
    if n > maxi:
        return "trop_facile"
    return "garder"


def filtrer(resultats: dict[str, Iterable[bool]], essais: int = 8, mini: int = 1,
            maxi: int = 6) -> tuple[list[str], dict[str, str]]:
    """(ids gardés, {id écarté: raison})."""
    gardes, ecartes = [], {}
    for ident in sorted(resultats):
        raison = classer(resultats[ident], essais, mini, maxi)
        if raison == "garder":
            gardes.append(ident)
        else:
            ecartes[ident] = raison
    return gardes, ecartes
