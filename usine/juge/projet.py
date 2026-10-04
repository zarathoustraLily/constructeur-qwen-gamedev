"""Juger un projet complet sur une copie de travail jetable.

Étapes, dans l'ordre : import → check_script (chaque .gd) → load_scene (chaque .tscn)
→ run_tests. Le verdict porte l'étape où le projet échoue, ou « run_tests » s'il passe tout.
Le projet source n'est jamais modifié (règle 7 : on juge une copie).
"""

from __future__ import annotations

import shutil
import tempfile
import time
from pathlib import Path
from typing import Any, Iterable

from usine import config as cfg
from usine import socle
from usine.juge import godot as juges
from usine.juge.verdict import nouveau_verdict

ETAPES = ("import", "check_script", "load_scene", "run_tests")
IGNORES_COPIE = shutil.ignore_patterns(".godot", "reports", "__pycache__", ".import")
DOSSIER_TESTS_JUGE = "tests_juge"


def _hors_addons(projet: Path, motif: str) -> list[Path]:
    return sorted(p for p in projet.rglob(motif)
                  if "addons" not in p.relative_to(projet).parts and ".godot" not in p.relative_to(projet).parts)


def preparer_copie(source: Path, destination: Path, superpositions: Iterable[Path] = (),
                   tests_caches: Path | None = None) -> Path:
    """Copie `source` dans `destination`, applique les superpositions, pose le socle (usine/socle.py),
    ajoute GdUnit4 et les tests cachés."""
    destination = Path(destination)
    shutil.copytree(source, destination, ignore=IGNORES_COPIE)
    for sup in superpositions:
        shutil.copytree(sup, destination, dirs_exist_ok=True, ignore=IGNORES_COPIE)
    socle.etendre(destination)
    addon = destination / "addons" / "gdUnit4"
    if not addon.is_dir():
        shutil.copytree(cfg.chemin_gdunit4(), addon, ignore=IGNORES_COPIE)
    if tests_caches is not None:
        shutil.copytree(tests_caches, destination / DOSSIER_TESTS_JUGE, dirs_exist_ok=True)
    return destination


def juger_sur_place(projet: Path, filtre: str | Iterable[str] | None = None, etapes: Iterable[str] = ETAPES,
                    godot: Path | None = None) -> dict[str, Any]:
    """Enchaîne les étapes sur `projet` (qui doit être une copie de travail)."""
    projet = Path(projet)
    etapes = [e for e in ETAPES if e in set(etapes)]
    debut = time.monotonic()
    verdict = nouveau_verdict(etapes[-1] if etapes else "aucune", ok=True)
    resultats: list[dict[str, Any]] = []

    if "import" in etapes or any(e in etapes for e in ("check_script", "load_scene", "run_tests")):
        imp = juges.importer(projet, godot)
        if not imp["ok"]:
            resultats.append(imp)
    # Scripts et scènes : un lancement pour tout le lot, puis le juge élément par élément
    # seulement pour ce que le lot n'a pas validé (verdict identique, beaucoup moins de lancements).
    if not resultats and "check_script" in etapes:
        scripts = [s for s in _hors_addons(projet, "*.gd") if DOSSIER_TESTS_JUGE not in s.relative_to(projet).parts]
        a_revoir = set(juges.verifier_lot(projet, "scripts", scripts, godot)["a_revoir"])
        for script in scripts:
            if juges.chemin_res(script, projet) not in a_revoir:
                continue
            r = juges.check_script(script, projet, godot)
            if not r["ok"]:
                resultats.append(r)
    if not resultats and "load_scene" in etapes:
        scenes = _hors_addons(projet, "*.tscn")
        a_revoir = set(juges.verifier_lot(projet, "scenes", scenes, godot)["a_revoir"])
        for scene in scenes:
            if juges.chemin_res(scene, projet) not in a_revoir:
                continue
            r = juges.load_scene(scene, projet, godot)
            if not r["ok"]:
                resultats.append(r)
    if not resultats and "run_tests" in etapes:
        r = juges.run_tests(projet, filtre, godot)
        r.pop("journal", None)
        verdict["tests"] = r["tests"]
        if not r["ok"]:
            resultats.append(r)

    if resultats:
        verdict["ok"] = False
        verdict["etape"] = resultats[0]["etape"]
        for r in resultats:
            verdict["erreurs"].extend(r["erreurs"])
    verdict["duree_s"] = round(time.monotonic() - debut, 3)
    return verdict


def juger_projet(projet: Path, filtre: str | Iterable[str] | None = None, etapes: Iterable[str] = ETAPES,
                 superpositions: Iterable[Path] = (), tests_caches: Path | None = None,
                 godot: Path | None = None) -> dict[str, Any]:
    """Juge `projet` sur une copie temporaire, détruite ensuite."""
    with tempfile.TemporaryDirectory(prefix="usine_juge_") as tmp:
        copie = preparer_copie(Path(projet), Path(tmp) / "projet", superpositions, tests_caches)
        return juger_sur_place(copie, filtre, etapes, godot)
