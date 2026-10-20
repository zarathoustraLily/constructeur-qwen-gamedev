"""Juge d'observation (compétence O1) : étape « observation », après le juge commun.

Le candidat est importé dans une copie de travail ; les séquences de la tâche y sont jouées, avec le
monde de vérité de la référence posé en fantôme ; chaque règle (partie.py) doit tenir sur chaque
séquence. Le matériel du juge vit dans tests_caches/observation/ de la tâche (règle 3 : jamais dans
l'espace de l'agent) :
    config.json         description du jeu (copie de usine/observation/jeux/<jeu>.json)
    monde_verite.tscn   formes de collision de la référence, écrites par partie.ecrire_monde

Champ `observation` de tache.json : {"jeu": "kart", "sequences": ["virages", "rocher", …]}.
Catégories d'erreur ajoutées au format commun : partie_<règle> (partie_gravite, partie_traversee…).
Comme pour E, ce paquet vit hors de usine/juge : son code a sa propre clé de cache
(partie.version_observation), qui inclut la version du juge commun.
"""

from __future__ import annotations

import hashlib
import json
import time
from pathlib import Path
from typing import Any, Iterable

from usine import config as cfg
from usine.observation import partie

ETAPE = "observation"
CATEGORIES = tuple(f"partie_{r}" for r in partie.REGLES)


def materiel(dossier: Path) -> tuple[Path, Path]:
    d = Path(dossier) / "tests_caches" / "observation"
    return d / "config.json", d / "monde_verite.tscn"


def _hachage(chemin: Path) -> str:
    return hashlib.sha256(Path(chemin).read_bytes()).hexdigest()


def _erreur(regle: str, sequence: str, r: dict[str, Any]) -> dict[str, Any]:
    return {"fichier": None, "ligne": None, "categorie": f"partie_{regle}",
            "message": f"séquence « {sequence} », {partie.ligne_faute(regle, r)}"}


def evaluer(dossier: Path, tache: dict[str, Any], source: Path, superpositions: Iterable[Path] = (),
            repetition: int | None = None) -> dict[str, Any]:
    """Étape observation seule. Renvoie {ok, erreurs, metriques, duree_s}."""
    from usine.efficience.mesure import Copie, ErreurMesure, contenu
    dossier = Path(dossier)
    superpositions = list(superpositions)
    obs = tache["observation"]
    sequences = list(obs["sequences"])
    config, monde = materiel(dossier)
    cle = None
    if repetition is not None:
        from usine.juge import cache
        cle = hashlib.sha256(json.dumps(["observation", partie.version_observation(), cfg.version_godot(),
                                         contenu(source, superpositions), _hachage(config), _hachage(monde),
                                         sequences, repetition]).encode("utf-8")).hexdigest()
        connu = cache.lire(cle)
        if connu is not None:
            return {**connu, "depuis_cache": True}
    debut = time.monotonic()
    erreurs: list[dict[str, Any]] = []
    metriques: dict[str, Any] = {}
    regles = partie.lire_config(config)["regles"]
    try:
        with Copie.ouvrir(source, superpositions) as copie:
            traces = partie.lancer(copie.projet, config, sequences, monde)
    except (ErreurMesure, partie.ErreurObservation) as e:
        erreurs.append({"fichier": None, "ligne": None, "categorie": "autre",
                        "message": f"observation impossible : {str(e)[:600]}"})
        return {"ok": False, "erreurs": erreurs, "metriques": metriques, "duree_s": round(time.monotonic() - debut, 3)}
    for nom in sequences:
        ev = partie.evaluer(traces[nom], regles)
        metriques[nom] = {"cassees": {r: ev[r] for r in partie.cassees(ev)}, "marges": partie.marges(traces[nom])}
        erreurs += [_erreur(r, nom, ev[r]) for r in partie.cassees(ev)]
    resultat = {"ok": not erreurs, "erreurs": erreurs, "metriques": metriques,
                "duree_s": round(time.monotonic() - debut, 3)}
    if cle is not None:
        from usine.juge import cache
        cache.ecrire(cle, resultat)
    return {**resultat, "depuis_cache": False}


def completer(verdict: dict[str, Any], dossier: Path, tache: dict[str, Any], source: Path,
              superpositions: Iterable[Path] = (), repetition: int | None = None) -> dict[str, Any]:
    """Ajoute l'étape observation à un verdict commun qui passe (le jeu se charge sans erreur)."""
    if not verdict["ok"]:
        return verdict
    o = evaluer(dossier, tache, source, superpositions, repetition)
    sortie = dict(verdict)
    sortie["etape"] = ETAPE
    sortie["ok"] = o["ok"]
    sortie["erreurs"] = list(verdict["erreurs"]) + o["erreurs"]
    sortie["observation"] = o["metriques"]
    sortie["duree_s"] = round(float(verdict.get("duree_s", 0.0)) + o["duree_s"], 3)
    if "depuis_cache" in verdict or "depuis_cache" in o:
        sortie["depuis_cache"] = bool(verdict.get("depuis_cache")) and bool(o.get("depuis_cache"))
    return sortie
