"""Juge d'observation visuelle (compétence O1 par l'image) : étape « observation_visuelle », après le juge commun.

Le candidat est importé dans une copie de travail. Les tests d'origine de l'étape y sont remis par-dessus (l'agent
a pu toucher aux siens : règle 3), puis lancés : aucun ne doit échouer. Chaque vue est rendue (visuel.rendre) et
comparée à l'image de référence : au plus visuel.PART_IDENTIQUE de ses pixels peuvent changer.

Matériel du juge, dans tests_caches/observation_visuelle/ de la tâche (jamais dans l'espace de l'agent) :
    vues.json       les vues : [{"nom": "jour", "args": []}, …]
    <vue>.png       l'image de référence de chaque vue, rendue à la génération sur la même machine
    tests/…         les tests d'origine de l'étape (scripts `extends SceneTree` de 7_tests/), même chemin

Champ `observation_visuelle` de tache.json : {"vues": [...], "seuil_pixel": 24, "part_identique": 0.001}.
Catégories d'erreur ajoutées au format commun : `rendu` (le rendu affiche une erreur ou ne se fait pas) et
`image` (une vue diffère de la référence), plus `test_failure` pour un test de l'étape qui échoue.
"""

from __future__ import annotations

import hashlib
import json
import shutil
import time
from pathlib import Path
from typing import Any, Iterable

from usine import config as cfg
from usine.observation import partie, visuel

ETAPE = "observation_visuelle"
DOSSIER = "observation_visuelle"


def materiel(dossier: Path) -> Path:
    return Path(dossier) / "tests_caches" / DOSSIER


def materiel_complet(dossier: Path) -> bool:
    d = materiel(dossier)
    if not (d / "vues.json").is_file():
        return False
    vues = json.loads((d / "vues.json").read_text(encoding="utf-8"))
    return bool(vues) and all((d / f"{v['nom']}.png").is_file() for v in vues)


def _hachage_materiel(d: Path) -> str:
    h = hashlib.sha256()
    for f in sorted(p for p in d.rglob("*") if p.is_file()):
        h.update(f.relative_to(d).as_posix().encode("utf-8"))
        h.update(hashlib.sha256(f.read_bytes()).hexdigest().encode("ascii"))
    return h.hexdigest()


def lancer_tests(projet: Path, delai_s: float = 300) -> list[dict[str, Any]]:
    """Les tests de l'étape (scripts SceneTree de 7_tests, comme usine/cours/verifier.py) : une erreur par test
    qui échoue."""
    from usine.cours.verifier import nettoyer_sortie, test_reussi, tests
    from usine.processus import executer
    erreurs: list[dict[str, Any]] = []
    for res in tests(projet):
        r = executer([cfg.chemin_godot(), "--headless", "--path", projet, "-s", res], delai_s=delai_s)
        texte = nettoyer_sortie(r.sortie, projet)
        if not test_reussi(r.code, texte):
            lignes = [l for l in texte.splitlines() if "ÉCHEC" in l or "ERROR" in l][:3]
            erreurs.append({"fichier": res, "ligne": None, "categorie": "test_failure",
                            "message": f"test de l'étape en échec (code {r.code}) : " + " | ".join(lignes)[:400]})
    return erreurs


def regarder(projet: Path, vues: list[dict[str, Any]], references: Path, dossier_rendus: Path,
             seuil: int = visuel.SEUIL_PIXEL, part_identique: float = visuel.PART_IDENTIQUE
             ) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    """Rend les vues de `projet` (importé) et les compare aux images de `references`. (erreurs, métriques)."""
    erreurs: list[dict[str, Any]] = []
    metriques: dict[str, Any] = {}
    rendus = visuel.rendre(projet, vues, dossier_rendus)
    for vue in vues:
        nom = vue["nom"]
        r = rendus[nom]
        if r["erreurs"] or r["image"] is None:
            detail = " | ".join(r["erreurs"][:4]) or "aucune image produite"
            erreurs.append({"fichier": None, "ligne": None, "categorie": "rendu",
                            "message": f"vue « {nom} » : rendu en erreur : {detail}"[:600]})
            metriques[nom] = {"rendu": "erreur"}
            continue
        c = visuel.comparer(Path(references) / f"{nom}.png", r["image"], projet, seuil)
        metriques[nom] = {"part": c["part"], "boite": c["boite"], "ecart_max": c["ecart_max"]}
        if c["part"] > part_identique:
            erreurs.append({"fichier": None, "ligne": None, "categorie": "image", "message": visuel.decrire(c, nom)})
    return erreurs, metriques


def evaluer(dossier: Path, tache: dict[str, Any], source: Path, superpositions: Iterable[Path] = (),
            repetition: int | None = None) -> dict[str, Any]:
    """Étape observation_visuelle seule. Renvoie {ok, erreurs, metriques, duree_s}."""
    from usine.efficience.mesure import Copie, ErreurMesure, contenu
    dossier = Path(dossier)
    superpositions = list(superpositions)
    obs = tache[DOSSIER]
    mat = materiel(dossier)
    vues = json.loads((mat / "vues.json").read_text(encoding="utf-8"))
    seuil = int(obs.get("seuil_pixel", visuel.SEUIL_PIXEL))
    part_identique = float(obs.get("part_identique", visuel.PART_IDENTIQUE))
    cle = None
    if repetition is not None:
        from usine.juge import cache
        cle = hashlib.sha256(json.dumps([ETAPE, partie.version_observation(), cfg.version_godot(),
                                         contenu(source, superpositions), _hachage_materiel(mat), seuil,
                                         part_identique, repetition]).encode("utf-8")).hexdigest()
        connu = cache.lire(cle)
        if connu is not None:
            return {**connu, "depuis_cache": True}
    debut = time.monotonic()
    erreurs: list[dict[str, Any]] = []
    metriques: dict[str, Any] = {}
    try:
        with Copie.ouvrir(source, superpositions) as copie:
            tests_origine = mat / "tests"
            if tests_origine.is_dir():
                shutil.copytree(tests_origine, copie.projet, dirs_exist_ok=True)
            erreurs += lancer_tests(copie.projet)
            e, metriques = regarder(copie.projet, vues, mat, copie.racine / "rendus", seuil, part_identique)
            erreurs += e
    except (ErreurMesure, visuel.ErreurComparaison) as e:
        erreurs.append({"fichier": None, "ligne": None, "categorie": "autre",
                        "message": f"observation visuelle impossible : {str(e)[:600]}"})
        return {"ok": False, "erreurs": erreurs, "metriques": metriques, "duree_s": round(time.monotonic() - debut, 3)}
    resultat = {"ok": not erreurs, "erreurs": erreurs, "metriques": metriques,
                "duree_s": round(time.monotonic() - debut, 3)}
    if cle is not None:
        from usine.juge import cache
        cache.ecrire(cle, resultat)
    return {**resultat, "depuis_cache": False}


def completer(verdict: dict[str, Any], dossier: Path, tache: dict[str, Any], source: Path,
              superpositions: Iterable[Path] = (), repetition: int | None = None) -> dict[str, Any]:
    """Ajoute l'étape observation_visuelle à un verdict commun qui passe (le projet se charge sans erreur)."""
    if not verdict["ok"]:
        return verdict
    o = evaluer(dossier, tache, source, superpositions, repetition)
    sortie = dict(verdict)
    sortie["etape"] = ETAPE
    sortie["ok"] = o["ok"]
    sortie["erreurs"] = list(verdict["erreurs"]) + o["erreurs"]
    sortie[DOSSIER] = o["metriques"]
    sortie["duree_s"] = round(float(verdict.get("duree_s", 0.0)) + o["duree_s"], 3)
    if "depuis_cache" in verdict or "depuis_cache" in o:
        sortie["depuis_cache"] = bool(verdict.get("depuis_cache")) and bool(o.get("depuis_cache"))
    return sortie
