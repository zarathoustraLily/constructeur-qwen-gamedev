"""Famille « analyser sans rien modifier » (analyse au palier de 2 048 jetons, avec le plan ; décision 3).

Les exemples d'analyse des bases au format d'OpenCode (`usine/cours/base/analyse.py`) reprennent le début d'une session de
débogage vérifiée : les mêmes commandes, les mêmes sorties réelles, la même lecture, puis le diagnostic. Le gros de leurs
jetons est la consigne et les outils d'OpenCode (13 351 jetons). Sans eux, avec le plan comme message système, ils tiennent
dans ce palier. Rien n'est relancé : tout vient de la session déjà vérifiée.

    python -m usine.paires analyse_sessions
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Callable

from usine import config as cfg
from usine.paires import format as fmt

FAMILLE = "analyse_session"
PLAFOND = 2048


def paire(cours: str, exemple: dict[str, Any]) -> tuple[dict[str, Any] | None, str]:
    tours = [m for m in exemple["messages"] if m["role"] != "system"]
    sujet = exemple["sujet"].split(",")[0].strip()
    q = fmt.paire_tours(FAMILLE, sujet, "analyse", tours, {"cours": cours, "tache": exemple["tache_id"], "palier": 2},
                        systeme=fmt.plan())
    return (q, "") if q["jetons"] <= PLAFOND else (None, f"trop longue ({q['jetons']} jetons)")


def generer(donnees: Path | None = None, journal: Callable[[str], None] = print) -> dict[str, Any]:
    racine = Path(donnees or cfg.dossier_donnees())
    paires, rejets = [], []
    for f in sorted((racine / "cours").glob("*/base/livraison/base_*.jsonl")):
        if f.stem.endswith("_sharegpt"):
            continue
        cours = f.parents[2].name
        for ligne in f.read_text(encoding="utf-8").splitlines():
            exemple = json.loads(ligne)
            if exemple["type"] != "analyse":
                continue
            q, raison = paire(cours, exemple)
            if q is None:
                rejets.append(f"{exemple['tache_id']} : {raison}")
            else:
                paires.append(q)
    sortie = fmt.dossier(FAMILLE, donnees)
    fmt.ecrire(paires, sortie / "paires.jsonl")
    bilan = {"famille": FAMILLE, "paires": len(paires), "rejets": len(rejets), "exemples_de_rejets": rejets[:8],
             "jetons_max": max((p["jetons"] for p in paires), default=0),
             "jetons_reponse": sum(p["jetons_reponse"] for p in paires)}
    (sortie / "bilan.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    journal(f"{FAMILLE} : {len(paires)} paires, {len(rejets)} écartées")
    return bilan
