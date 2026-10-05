"""Chaîne complète : candidats → portillon → gel → exclusion → tâches acceptées, avec rapport.

    python -m usine.portillon chaine [--graine 1] [--sortie donnees] [--travailleurs 4]

Dans <sortie>/ :
  candidats/                 toutes les candidates (usine.generateurs.produire)
  geles/manifeste.json       jeux gelés (créé une fois, réutilisé ensuite) + geles/<C>/<id>/
  taches/<C>/<id>/           tâches acceptées pour l'entraînement (origine « generateur:* »)
  portillon/journal.jsonl    une ligne par décision (acceptée ou rejet + raison)
  portillon/rapport.json     volumes par compétence et statistiques de rejet par raison

`competences` (par exemple ["E"]) ne produit et ne juge que ces compétences : les tâches
acceptées des autres compétences restent dans taches/, et le gel existant n'est complété que
pour elles (avec `completer_gel`) ou créé s'il n'existe pas.

Le cache des verdicts (donnees/cache_juge) est partagé : une seconde exécution avec la même
graine rejoue la génération et le tirage, et réutilise les verdicts déjà calculés.
"""

from __future__ import annotations

import json
import shutil
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Any

from usine.generateurs.efficience import NOMBRE_DEFAUT as NOMBRE_E
from usine.generateurs.produire import produire
from usine.portillon.dedoublonnage import Index, signature_tache
from usine.portillon.exclusion import Exclusion
from usine.portillon.gel import geler, lire_manifeste
from usine.portillon.regles import Decision, Reglages, evaluer
from usine.taches import lire_tache, lister_taches


def _ecrire(chemin: Path, texte: str) -> None:
    chemin.parent.mkdir(parents=True, exist_ok=True)
    chemin.write_text(texte, encoding="utf-8", newline="\n")


def chaine(sortie: Path, graine: int, travailleurs: int = 4, nombre_f1: int = 40, cible_gel: int = 50,
           part_gel: float = 0.5, afficher=print, sources: list[str] | None = None,
           completer_gel: bool = False, competences: list[str] | None = None,
           nombre_e: int = NOMBRE_E) -> dict[str, Any]:
    """`completer_gel` : un gel existant reçoit des tâches des nouvelles sources (jamais de retrait),
    à faire avant tout entraînement ; sinon il est réutilisé tel quel."""
    sortie = Path(sortie)
    reglages = Reglages.depuis_config(graine)
    debut = time.monotonic()

    afficher("== 1. Production des candidates")
    prod = produire(sortie / "candidats", graine, nombre_f1=nombre_f1, travailleurs=travailleurs, afficher=afficher,
                    sources=sources, competences=competences, nombre_e=nombre_e)
    candidats = sorted(prod.taches, key=lambda d: (d.parent.name, d.name))

    afficher(f"== 2. Portillon ({len(candidats)} candidates, {reglages.repetitions} répétitions, "
             f"seuil mutants {reglages.seuil_mutants:.0%}, {reglages.mutants_max} mutants max par tâche)")
    faites = [0]

    def evaluer_suivi(d: Path) -> Decision:
        dec = evaluer(d, reglages)
        faites[0] += 1
        if faites[0] % 20 == 0:
            afficher(f"   {faites[0]}/{len(candidats)} évaluées ({time.monotonic() - debut:.0f} s)")
        return dec

    with ThreadPoolExecutor(max_workers=max(1, travailleurs)) as pool:
        decisions = dict(zip(candidats, pool.map(evaluer_suivi, candidats)))

    # Doublons exacts entre candidates : la première (ordre des ids) reste.
    vues: dict[str, str] = {}
    for d in candidats:
        dec = decisions[d]
        if not dec.acceptee:
            continue
        empreinte = lire_tache(d)["empreinte"]
        if empreinte in vues:
            dec.acceptee, dec.raison, dec.detail = False, "doublon_candidat", f"même empreinte que {vues[empreinte]}"
        else:
            vues[empreinte] = dec.id

    qualifiees: dict[str, list[Path]] = {}
    for d in candidats:
        if decisions[d].acceptee:
            qualifiees.setdefault(decisions[d].competence, []).append(d)

    afficher("== 3. Gel")
    deja = lire_manifeste(sortie)
    if completer_gel and deja is not None:
        # Les tâches déjà gelées ne se retirent pas et ne se comptent qu'une fois (gel.tirer).
        geles_ids = {t["id"] for e in deja["competences"].values() for t in e["taches"]}
        qualifiees = {c: [d for d in ds if d.name not in geles_ids] for c, ds in qualifiees.items()}
    manifeste = geler(sortie, qualifiees, graine, cible_gel, part_gel, completer=completer_gel)
    gelees = {t["id"] for e in manifeste["competences"].values() for t in e["taches"]}
    exclusion = Exclusion(manifeste, seuil=reglages.seuil_fragments)

    afficher("== 4. Exclusion des jeux gelés et écriture des tâches acceptées")
    dossier_taches = sortie / "taches"
    for ancien in lister_taches(dossier_taches):
        t = lire_tache(ancien)
        if str(t.get("origine", "")).startswith("generateur:") and (not competences or t["competence"] in competences):
            shutil.rmtree(ancien)
    acceptees: list[Path] = []
    for d in candidats:
        dec = decisions[d]
        if not dec.acceptee:
            continue
        if dec.id in gelees:
            dec.mesures["gelee"] = True
            continue
        doublon = exclusion.tache_exclue(d)
        if doublon:
            dec.acceptee, dec.raison, dec.detail = False, "doublon_gele", f"{doublon[0]} avec {doublon[1]}"
            continue
        cible = dossier_taches / d.parent.name / d.name
        shutil.copytree(d, cible)
        acceptees.append(cible)

    # Contrôle final : aucune tâche du dossier d'entraînement (modèles compris) ne double un gel.
    # Une tâche modèle (godot/taches_modeles, installée à la main) qui double une tâche gelée
    # quitte le dossier d'entraînement (règle 4) ; `python -m usine.taches installer` la remettrait.
    modeles_retires = []
    for t in lister_taches(dossier_taches):
        if exclusion.tache_exclue(t) and not str(lire_tache(t).get("origine", "")).startswith("generateur:"):
            modeles_retires.append(t.name)
            shutil.rmtree(t)
    restants = [t for t in lister_taches(dossier_taches) if exclusion.tache_exclue(t)]

    lignes = [json.dumps(decisions[d].ligne(), ensure_ascii=False, sort_keys=True) for d in candidats]
    _ecrire(sortie / "portillon" / "journal.jsonl", "\n".join(lignes) + "\n")
    rapport = _rapport(candidats, decisions, prod.ecartes, manifeste, acceptees, restants, graine, reglages)
    rapport["modeles_retires"] = sorted(modeles_retires)
    _ecrire(sortie / "portillon" / "rapport.json", json.dumps(rapport, ensure_ascii=False, indent=1, sort_keys=True) + "\n")
    rapport["duree_s"] = round(time.monotonic() - debut)
    return rapport


def _rapport(candidats, decisions, ecartes, manifeste, acceptees, restants, graine, reglages) -> dict[str, Any]:
    par_comp: dict[str, dict[str, Any]] = {}
    for d in candidats:
        dec = decisions[d]
        c = par_comp.setdefault(dec.competence, {"candidates": 0, "qualifiees": 0, "gelees": 0, "acceptees": 0,
                                                 "rejets": Counter()})
        c["candidates"] += 1
        if dec.acceptee or dec.raison == "doublon_gele":
            c["qualifiees"] += 1
        if dec.mesures.get("gelee"):
            c["gelees"] += 1
        elif dec.acceptee:
            c["acceptees"] += 1
        if dec.raison:
            c["rejets"][dec.raison] += 1
    for c in par_comp.values():
        c["rejets"] = dict(sorted(c["rejets"].items()))
    rejets = Counter(decisions[d].raison for d in candidats if decisions[d].raison)
    return {
        "graine": graine,
        "reglages": vars(reglages),
        "competences": dict(sorted(par_comp.items())),
        "rejets_par_raison": dict(sorted(rejets.items())),
        "ecartes_a_la_generation": dict(sorted(Counter(e["raison"] for e in ecartes).items())),
        "acceptees": sorted(f"{p.parent.name}/{p.name}" for p in acceptees),
        "acceptees_empreintes": {p.name: lire_tache(p)["empreinte"] for p in sorted(acceptees)},
        "gelees": {c: [t["id"] for t in e["taches"]] for c, e in sorted(manifeste["competences"].items())},
        # Empreintes du gel : un rejeu doit redonner les mêmes octets, pas seulement les mêmes ids.
        "gelees_empreintes": {t["id"]: t["empreinte"] for e in manifeste["competences"].values() for t in e["taches"]},
        "doublons_avec_geles": [p.name for p in restants],
        "verdicts_depuis_cache": sum(decisions[d].mesures.get("depart_cache", 0)
                                     + decisions[d].mesures.get("reference_cache", 0) for d in candidats),
    }


def afficher_rapport(r: dict[str, Any], afficher=print) -> None:
    afficher(f"\n{'compétence':<11}{'candidates':>11}{'qualifiées':>11}{'gelées':>8}{'acceptées':>10}  rejets")
    for comp, c in r["competences"].items():
        rejets = ", ".join(f"{k} {v}" for k, v in c["rejets"].items()) or "—"
        afficher(f"{comp:<11}{c['candidates']:>11}{c['qualifiees']:>11}{c['gelees']:>8}{c['acceptees']:>10}  {rejets}")
    total = {k: sum(c[k] for c in r["competences"].values()) for k in ("candidates", "qualifiees", "gelees", "acceptees")}
    afficher(f"{'TOTAL':<11}{total['candidates']:>11}{total['qualifiees']:>11}{total['gelees']:>8}{total['acceptees']:>10}")
    afficher("\nRejets du portillon par raison : " + (", ".join(f"{k} {v}" for k, v in r["rejets_par_raison"].items()) or "aucun"))
    afficher("Écartés à la génération : " + (", ".join(f"{k} {v}" for k, v in r["ecartes_a_la_generation"].items()) or "aucun"))
    comps = [c for c, v in r["competences"].items() if v["acceptees"]]
    afficher(f"Acceptées : {len(r['acceptees'])} sur {len(comps)} compétences ({', '.join(comps)})")
    if r.get("modeles_retires"):
        afficher(f"Tâches modèles retirées de taches/ (doublent un gel) : {', '.join(r['modeles_retires'])}")
    afficher(f"Doublons avec les jeux gelés dans taches/ : {len(r['doublons_avec_geles'])}")
    afficher(f"Verdicts relus dans le cache : {r['verdicts_depuis_cache']}")
