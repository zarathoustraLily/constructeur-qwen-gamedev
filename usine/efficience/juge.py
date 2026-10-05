"""Juge d'efficience (compétence E) : étape « mesure_efficience », après le juge commun.

Seuils (spec de laurent, 2026-10-04), tous relatifs à la référence de la tâche sauf les allocations :
  - allocations d'objets entre la fin de l'échauffement et la fin de la fenêtre : 0 ;
  - lots de dessin (médiane sur la fenêtre) ≤ lots de la référence × 1,05 ;
  - temps par image ≤ temps de la référence × 1,15, médianes sur 3 exécutions alternées,
    mesuré sur la même machine au moment de juger (jamais comparé à une valeur enregistrée) ;
    seulement pour les tâches qui le déclarent (`mesure_efficience.temps`) ;
  - rendu intact : contrôle statique (rendu_intact.py) et signature de ce qui serait affiché,
    identique à celle de la référence aux images de contrôle. Un rendu dégradé est refusé même
    si l'efficience est bonne.

Le projet comparé à lui-même (le candidat EST la référence, octet pour octet) a un rapport de
temps de 1 par définition : on ne mesure pas le bruit de la machine contre lui-même.

Catégories d'erreur ajoutées au format commun : efficience_allocations, efficience_draw_calls,
efficience_temps, rendu_degrade (mêmes noms que les raisons de rejet du portillon).
"""

from __future__ import annotations

import hashlib
import json
import time
from pathlib import Path
from typing import Any, Iterable

from usine import config as cfg
from usine.efficience import mesure, rendu_intact
from usine.efficience.mesure import Copie, ErreurMesure, Reglages

ETAPE = "mesure_efficience"
PLAFOND_LOTS = 1.05
PLAFOND_TEMPS = 1.15
ALLOCATIONS_MAX = 0
CATEGORIES = ("efficience_allocations", "efficience_draw_calls", "efficience_temps", "rendu_degrade")


def _erreur(categorie: str, message: str) -> dict[str, Any]:
    return {"fichier": None, "ligne": None, "categorie": categorie, "message": message}


def _cle(*morceaux: Any) -> str:
    return hashlib.sha256(json.dumps(morceaux, sort_keys=True, default=str).encode("utf-8")).hexdigest()


def _cache_lire(cle: str) -> dict[str, Any] | None:
    from usine.juge import cache
    return cache.lire(cle)


def _cache_ecrire(cle: str, valeur: dict[str, Any]) -> None:
    from usine.juge import cache
    cache.ecrire(cle, valeur)


def mesure_reference(dossier: Path, reglages: Reglages) -> dict[str, Any]:
    """Mesure déterministe de la référence (départ + superposition), en cache par contenu."""
    dossier = Path(dossier)
    sups = [dossier / "reference"]
    cle = _cle("efficience-ref", mesure.version_efficience(), cfg.version_godot(),
               mesure.contenu(dossier / "depart", sups), reglages)
    connue = _cache_lire(cle)
    if connue is not None:
        return connue
    m = mesure.mesurer_deterministe(dossier / "depart", sups, reglages)
    _cache_ecrire(cle, m)
    return m


def comparer_rendu(attendu: dict[str, Any], obtenu: dict[str, Any]) -> list[str]:
    """Écarts entre deux listes de signatures de rendu (une par image de contrôle)."""
    ecarts = []
    par_image = {r["image"]: r["elements"] for r in obtenu.get("rendu", [])}
    for r in attendu.get("rendu", []):
        o = par_image.get(r["image"])
        a = r["elements"]
        if o is None:
            ecarts.append(f"image {r['image']} : non mesurée")
        elif o["hachage"] != a["hachage"]:
            diff = []
            for genre in sorted(set(a["resume"]) | set(o["resume"])):
                na, no = a["resume"].get(genre, 0), o["resume"].get(genre, 0)
                if na != no:
                    diff.append(f"{genre} {na}→{no}")
            ecarts.append(f"image {r['image']} : affichage différent de la référence"
                          + (f" ({', '.join(diff[:4])})" if diff else " (mêmes éléments, positions, couleurs ou "
                                                                       "matériaux différents)"))
    return ecarts


def evaluer(dossier: Path, tache: dict[str, Any], source: Path, superpositions: Iterable[Path] = (),
            repetition: int | None = None) -> dict[str, Any]:
    """Étape mesure_efficience seule. Renvoie {ok, erreurs, metriques, duree_s}."""
    dossier = Path(dossier)
    superpositions = list(superpositions)
    reglages = Reglages.depuis_tache(tache["mesure_efficience"])
    ref_sups = [dossier / "reference"]
    contenu_cand = mesure.contenu(source, superpositions)
    contenu_ref = mesure.contenu(dossier / "depart", ref_sups)
    cle = None
    if repetition is not None:
        cle = _cle("efficience", mesure.version_efficience(), cfg.version_godot(), contenu_cand, contenu_ref,
                   tache["mesure_efficience"], repetition)
        connu = _cache_lire(cle)
        if connu is not None:
            return {**connu, "depuis_cache": True}

    debut = time.monotonic()
    erreurs: list[dict[str, Any]] = []
    metriques: dict[str, Any] = {}
    attendu = tache["mesure_efficience"].get("reference", {})
    try:
        ref = mesure_reference(dossier, reglages)
        with Copie.ouvrir(source, superpositions) as cand_copie:
            # Rendu, contrôle statique : sur les fichiers composés de la référence et du candidat.
            with Copie.ouvrir(dossier / "depart", ref_sups) as ref_copie:
                ecarts = rendu_intact.comparer(ref_copie.projet, cand_copie.projet)
                cand = mesure.lancer(cand_copie.projet, reglages, "deterministe")
                if reglages.temps:
                    if contenu_cand == contenu_ref:
                        metriques["temps_cpu_relatif"] = {"ratio": 1.0, "plafond": PLAFOND_TEMPS, "ok": True,
                                                          "detail": "candidat identique à la référence"}
                    else:
                        t_cand, t_ref = mesure.mesurer_temps_croises(cand_copie, ref_copie, reglages)
                        ratio = mesure.mediane(t_cand) / max(1.0, mesure.mediane(t_ref))
                        metriques["temps_cpu_relatif"] = {
                            "ratio": round(ratio, 3), "plafond": PLAFOND_TEMPS, "ok": ratio <= PLAFOND_TEMPS,
                            "candidat_us": t_cand, "reference_us": t_ref}
    except ErreurMesure as e:
        erreurs.append(_erreur("autre", f"mesure d'efficience impossible : {str(e)[:600]}"))
        return {"ok": False, "erreurs": erreurs, "metriques": metriques,
                "duree_s": round(time.monotonic() - debut, 3)}

    ecarts += comparer_rendu(ref, cand)
    metriques["rendu"] = {"ok": not ecarts, "ecarts": ecarts[:10]}
    for e in ecarts[:5]:
        erreurs.append(_erreur("rendu_degrade", e))

    allocations = int(cand["allocations"])
    metriques["allocations_actives_apres_warmup"] = {"delta_objets": allocations,
                                                     "ok": allocations <= ALLOCATIONS_MAX}
    if allocations > ALLOCATIONS_MAX:
        erreurs.append(_erreur("efficience_allocations",
                               f"{allocations} objets alloués entre les images {reglages.echauffement} et "
                               f"{reglages.fin} (attendu : 0, réserve d'objets créée pendant l'échauffement)"))

    lots_ref = int(attendu.get("lots", ref["lots"]))
    plafond = lots_ref * PLAFOND_LOTS
    lots = int(cand["lots"])
    metriques["draw_calls"] = {"valeur": lots, "reference": lots_ref, "plafond": round(plafond, 2),
                               "ok": lots <= plafond, "methode": "structurelle"}
    if lots > plafond:
        erreurs.append(_erreur("efficience_draw_calls",
                               f"{lots} lots de dessin par image (médiane), référence {lots_ref}, plafond "
                               f"{plafond:.2f}"))

    temps = metriques.get("temps_cpu_relatif")
    if temps is not None and not temps["ok"]:
        erreurs.append(_erreur("efficience_temps",
                               f"temps par image {temps['ratio']:.2f} × celui de la référence (plafond "
                               f"{PLAFOND_TEMPS})"))

    # Ordre des erreurs : le rendu d'abord (une triche sur le rendu prime sur l'efficience).
    ordre = {c: k for k, c in enumerate(("rendu_degrade", "efficience_allocations", "efficience_draw_calls",
                                         "efficience_temps", "autre"))}
    erreurs.sort(key=lambda e: ordre.get(e["categorie"], 99))
    resultat = {"ok": not erreurs, "erreurs": erreurs, "metriques": metriques,
                "duree_s": round(time.monotonic() - debut, 3)}
    if cle is not None:
        _cache_ecrire(cle, resultat)
    return {**resultat, "depuis_cache": False}


def completer(verdict: dict[str, Any], dossier: Path, tache: dict[str, Any], source: Path,
              superpositions: Iterable[Path] = (), repetition: int | None = None) -> dict[str, Any]:
    """Ajoute l'étape mesure_efficience à un verdict commun qui passe (comportement intact)."""
    if not verdict["ok"]:
        return verdict
    e = evaluer(dossier, tache, source, superpositions, repetition)
    sortie = dict(verdict)
    sortie["etape"] = ETAPE
    sortie["ok"] = e["ok"]
    sortie["erreurs"] = list(verdict["erreurs"]) + e["erreurs"]
    sortie["metriques"] = e["metriques"]
    sortie["duree_s"] = round(float(verdict.get("duree_s", 0.0)) + e["duree_s"], 3)
    if "depuis_cache" in verdict or "depuis_cache" in e:
        sortie["depuis_cache"] = bool(verdict.get("depuis_cache")) and bool(e.get("depuis_cache"))
    return sortie
