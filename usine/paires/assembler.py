"""Assembleur des paliers de paires courtes (étapes B8 et D4 du suivi ; décision 19).

Réunit les paires de toutes les familles (`donnees/paires/<famille>/paires*.jsonl`) et fabrique le jeu d'un palier :

- palier 1 : paires sans plan, 1 024 jetons au plus (exception de la section 3) ;
- palier 2 : paires avec le plan en message système, 2 048 au plus (2 040 avec des images : marge du compte).

Contrôles, dans l'ordre : le palier (une paire de plus de 1 024 jetons sans le plan, ou dont le message système n'est
pas le plan, est refusée) ; les jetons recomptés avec le tokenizer de Qwen 3.8 (règle 5.8), aucune troncature ; les
jeux gelés et Starfox (`Exclusion.texte_exclu`, règle 4 ; le mot « starfox ») ; les doublons exacts ; au plus
`MEMES_REPONSES` paires par réponse identique (règle 7.7 : une case n'écrase pas les autres) ; puis le partage de la
décision 3 dans chaque sujet, en jetons de réponse (40/40/20). Un sujet auquel il manque un type n'est pas réduit : il
est signalé (trou à combler par la génération).

Sorties dans `donnees/entrainement/` : `palier_<N>.jsonl` (sharegpt, `format.vers_llamafactory`), l'entrée du palier
dans `dataset_info.json`, `controles_palier_<N>.json`.

    python -m usine.paires assembler --palier 1|2 [--graine G]
"""

from __future__ import annotations

import hashlib
import json
import random
import re
from pathlib import Path
from typing import Any, Callable

from usine import config as cfg
from usine.paires import format as fmt

PLAFONDS = {1: 1024, 2: 2048}
PLAFOND_IMAGES = 2040
CIBLE = {"création": 0.4, "débogage": 0.4, "analyse": 0.2}
MEMES_REPONSES = 20
STARFOX = re.compile(r"star\s*fox", re.I)


def palier(p: dict[str, Any]) -> tuple[int | None, str]:
    """(palier, "") ou (None, raison du refus)."""
    systeme = p["messages"][0]["content"] if p["messages"][0]["role"] == "system" else None
    if systeme is None:
        return (1, "") if p["jetons"] <= PLAFONDS[1] else (None, "plus de 1 024 jetons sans le plan (section 3)")
    if systeme != fmt.plan():
        return None, "message système qui n'est pas le plan"
    plafond = PLAFOND_IMAGES if p["images"] else PLAFONDS[2]
    return (2, "") if p["jetons"] <= plafond else (None, f"plus de {plafond} jetons")


def lire_familles(racine: Path) -> list[dict[str, Any]]:
    paires = []
    for fichier in sorted(racine.glob("*/paires*.jsonl")):
        for ligne in fichier.read_text(encoding="utf-8").splitlines():
            if ligne.strip():
                paires.append(json.loads(ligne))
    return paires


def _cle(p: dict[str, Any]) -> str:
    return hashlib.sha256(json.dumps(p["messages"], ensure_ascii=False).encode("utf-8")).hexdigest()


def equilibrer(paires: list[dict[str, Any]], rng: random.Random) -> tuple[list[dict[str, Any]], list[str]]:
    """Dans chaque sujet, la plus grande quantité qui respecte 40/40/20 en jetons de réponse ; on retire au hasard
    (graine fixe) dans les types en trop. Un sujet sans l'un des types est gardé tel quel et signalé."""
    par_sujet: dict[str, list[dict[str, Any]]] = {}
    for p in paires:
        par_sujet.setdefault(p["sujet"], []).append(p)
    gardees: list[dict[str, Any]] = []
    trous: list[str] = []
    for sujet, liste in sorted(par_sujet.items()):
        dispo = {t: sum(p["jetons_reponse"] for p in liste if p["type"] == t) for t in CIBLE}
        manquants = [t for t, n in dispo.items() if n == 0]
        if manquants:
            trous.append(f"{sujet} : pas de {', '.join(manquants)}")
            gardees += liste
            continue
        total = min(dispo[t] / CIBLE[t] for t in CIBLE)
        for t in CIBLE:
            du_type = [p for p in liste if p["type"] == t]
            rng.shuffle(du_type)
            budget, pris = CIBLE[t] * total, 0
            for p in du_type:
                if pris + p["jetons_reponse"] <= budget * 1.02 or pris == 0:
                    gardees.append(p)
                    pris += p["jetons_reponse"]
    return gardees, trous


def parts(paires: list[dict[str, Any]]) -> dict[str, dict[str, float]]:
    sortie: dict[str, dict[str, float]] = {}
    for sujet in sorted({p["sujet"] for p in paires}):
        liste = [p for p in paires if p["sujet"] == sujet]
        total = sum(p["jetons_reponse"] for p in liste) or 1
        sortie[sujet] = {t: round(sum(p["jetons_reponse"] for p in liste if p["type"] == t) / total, 3) for t in CIBLE}
    return sortie


def assembler(numero: int, graine: int = 1, donnees: Path | None = None,
              journal: Callable[[str], None] = print) -> dict[str, Any]:
    from usine.portillon.exclusion import Exclusion
    racine = Path(donnees or cfg.dossier_donnees())
    exclusion = Exclusion.charger(racine)
    rejets: dict[str, int] = {}
    gardees: list[dict[str, Any]] = []
    vues: set[str] = set()
    memes: dict[str, int] = {}

    def rejeter(raison: str) -> None:
        rejets[raison] = rejets.get(raison, 0) + 1

    toutes = lire_familles(racine / "paires")
    for p in toutes:
        recompte = fmt.jetons(p["messages"], p["images"])
        if recompte != p["jetons"]:
            p = dict(p, jetons=recompte)
        n, raison = palier(p)
        if n is None:
            rejeter(raison)
            continue
        if n != numero:
            continue
        texte = "\n".join(m["content"] for m in p["messages"] if m["role"] != "system")
        if STARFOX.search(texte):
            rejeter("Starfox")
            continue
        if exclusion and exclusion.texte_exclu(texte):
            rejeter("jeu gelé")
            continue
        cle = _cle(p)
        if cle in vues:
            rejeter("doublon exact")
            continue
        vues.add(cle)
        reponse = p["messages"][-1]["content"]
        memes[reponse] = memes.get(reponse, 0) + 1
        if memes[reponse] > MEMES_REPONSES:
            rejeter(f"plus de {MEMES_REPONSES} réponses identiques (règle 7.7)")
            continue
        gardees.append(p)
    equilibrees, trous = equilibrer(gardees, random.Random(graine))
    rejets["partage 40/40/20"] = len(gardees) - len(equilibrees)
    sortie = racine / "entrainement"
    nom = f"palier_{numero}"
    fmt.ecrire([fmt.vers_llamafactory(p) for p in equilibrees], sortie / f"{nom}.jsonl")
    from usine.entrainement import reglages
    info_chemin = sortie / "dataset_info.json"
    info = json.loads(info_chemin.read_text(encoding="utf-8")) if info_chemin.is_file() else {}
    info.update(reglages.info_jeu(nom, f"{nom}.jsonl", any(p["images"] for p in equilibrees)))
    info_chemin.write_text(json.dumps(info, indent=1, ensure_ascii=False), encoding="utf-8")
    jetons = sum(p["jetons"] for p in equilibrees)
    controles = {
        "palier": numero, "paires": len(equilibrees), "lues": len(toutes), "rejets": rejets, "trous": trous,
        "par_famille": {}, "par_type": {}, "parts_par_sujet": parts(equilibrees),
        "jetons_max": max((p["jetons"] for p in equilibrees), default=0), "jetons": jetons,
        "duree_estimee_5090_h": reglages.duree_estimee_h(jetons),
        "problemes": sum(1 for p in equilibrees if p["jetons"] > PLAFONDS[numero]),
    }
    for p in equilibrees:
        controles["par_famille"][p["famille"]] = controles["par_famille"].get(p["famille"], 0) + 1
        controles["par_type"][p["type"]] = controles["par_type"].get(p["type"], 0) + 1
    (sortie / f"controles_{nom}.json").write_text(json.dumps(controles, indent=1, ensure_ascii=False), encoding="utf-8")
    journal(f"{nom} : {len(equilibrees)} paires, {jetons} jetons, problèmes : {controles['problemes']}")
    return controles
