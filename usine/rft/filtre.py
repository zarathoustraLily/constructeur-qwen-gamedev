"""Filtre : le juge a noté chaque essai ; on garde, par tâche, la solution réussie la plus propre.

Trois contrôles d'abord (section 9 du document de laurent) : les tests passent (ok), la structure
est tenue (structure_ok), la session est saine (session_ok). Parmi les essais qui passent les
trois, le moins de violations au juge des règles (usine/regles, plus QA-03/07/08 de la session) ;
à égalité, la plus petite production du modèle (essais.longueur), puis le plus petit numéro
d'essai. Déterministe. Les tâches sans essai qui passe les trois contrôles passent au tour
suivant (a_refaire). Un registre ancien, sans ces colonnes, vaut 0 violation et contrôles tenus.

Filtre de difficulté (usine/portillon/difficulte.py, prévu dès la session 3) : une tâche réussie
plus de `maxi` fois sur N est déjà acquise ; elle n'apporte rien à l'entraînement et n'est pas
exportée (elle n'est pas non plus à refaire).
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
        reussis = [l for l in par_tache[tid] if _vrai(l["ok"]) and _vrai(l.get("structure_ok", True))
                   and _vrai(l.get("session_ok", True))]
        if reussis:
            retenus.append(min(reussis, key=lambda l: (int(l.get("violations") or 0), int(l["longueur"]),
                                                       int(l["essai"]))))
        else:
            a_refaire.append(tid)
    return retenus, a_refaire


def _vrai(v: Any) -> bool:
    return v is True or str(v).lower() in ("true", "1", "oui")


def appliquer_difficulte(registre: list[dict[str, Any]], retenus: list[dict[str, Any]], essais: int,
                         mini: int = 1, maxi: int | None = None) -> tuple[list[dict[str, Any]], dict[str, str]]:
    """(retenus gardés, {tâche écartée : raison}) ; sans plafond (maxi None), rien n'est écarté."""
    from usine.portillon.difficulte import classer
    if maxi is None:
        return retenus, {}
    reussites: dict[str, list[bool]] = {}
    for l in registre:
        reussites.setdefault(l["tache_id"], []).append(_vrai(l["ok"]))
    ecartes = {}
    gardes = []
    for l in retenus:
        raison = classer(reussites[l["tache_id"]], essais, mini, maxi)
        if raison == "garder":
            gardes.append(l)
        else:
            ecartes[l["tache_id"]] = raison
    return gardes, ecartes
