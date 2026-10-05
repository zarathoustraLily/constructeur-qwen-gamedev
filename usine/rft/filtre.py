"""Filtre : le juge a noté chaque essai ; on garde, par tâche, la solution réussie la plus courte.

« Plus courte » : la plus petite production du modèle (contenu et appels d'outils des messages
assistant, essais.longueur) ; à égalité, le plus petit numéro d'essai. Déterministe.
Les tâches jamais réussies passent au tour suivant (a_refaire).
"""

from __future__ import annotations

from typing import Any


def retenir(registre: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], list[str]]:
    """(essais retenus, un par tâche réussie ; ids des tâches jamais réussies), dans l'ordre des ids."""
    par_tache: dict[str, list[dict[str, Any]]] = {}
    for ligne in registre:
        par_tache.setdefault(ligne["tache_id"], []).append(ligne)
    retenus, a_refaire = [], []
    for tid in sorted(par_tache):
        reussis = [l for l in par_tache[tid] if _vrai(l["ok"])]
        if reussis:
            retenus.append(min(reussis, key=lambda l: (int(l["longueur"]), int(l["essai"]))))
        else:
            a_refaire.append(tid)
    return retenus, a_refaire


def _vrai(v: Any) -> bool:
    return v is True or str(v).lower() in ("true", "1", "oui")
