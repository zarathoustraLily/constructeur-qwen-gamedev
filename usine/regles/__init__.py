"""Juge de règles d'architecture (document de laurent du 2026-10-11) : sans LLM (règle 2).

Il réunit le juge de structure (rangement, tableau des dossiers) et les contrôles par motifs
(controles.py). Chaque erreur porte l'identifiant de la règle violée, au format commun du verdict.
Un projet sans plan numéroté n'est pas jugé (verdict ok, `applicable` faux).

    python -m usine.regles verifier <projet> [res://fichier …]
"""

from __future__ import annotations

import time
from pathlib import Path
from typing import Any, Iterable

from usine.juge.verdict import nouveau_verdict
from usine.projet.index import lire_texte
from usine.regles.catalogue import MECANIQUES, REGLES, SESSION, texte
from usine.regles.controles import controler_projet_godot, controler_scene, controler_script
from usine.structure.regles import est_organise, verifier_projet

IGNORES = ("addons", ".godot")


def _fichiers(projet: Path) -> list[Path]:
    return sorted(f for f in projet.rglob("*") if f.is_file() and f.suffix in (".gd", ".tscn")
                  and f.relative_to(projet).parts[0] not in IGNORES)


def verifier_regles(projet: Path, fichiers: Iterable[str] | None = None) -> dict[str, Any]:
    """Verdict « regles » ; avec `fichiers` (res://…), seules leurs erreurs sont gardées."""
    debut = time.monotonic()
    projet = Path(projet)
    verdict = nouveau_verdict("regles", ok=True)
    verdict["applicable"] = est_organise(projet)
    if not verdict["applicable"]:
        verdict["duree_s"] = round(time.monotonic() - debut, 3)
        return verdict
    erreurs: list[dict[str, Any]] = list(verifier_projet(projet)["erreurs"])
    for f in _fichiers(projet):
        res = "res://" + f.relative_to(projet).as_posix()
        contenu = lire_texte(f)
        erreurs += controler_script(res, contenu) if f.suffix == ".gd" else controler_scene(res, contenu)
    erreurs += controler_projet_godot(lire_texte(projet / "project.godot"))
    if fichiers is not None:
        garder = set(fichiers)
        erreurs = [e for e in erreurs if e["fichier"] in garder]
    verdict["erreurs"] = sorted(erreurs, key=lambda e: (e["fichier"], e["ligne"] or 0, e["regle"]))
    verdict["ok"] = not erreurs
    verdict["duree_s"] = round(time.monotonic() - debut, 3)
    return verdict


def par_regle(verdict: dict[str, Any]) -> dict[str, int]:
    """Nombre de violations par identifiant de règle."""
    compte: dict[str, int] = {}
    for e in verdict.get("erreurs", []):
        compte[e.get("regle", "?")] = compte.get(e.get("regle", "?"), 0) + 1
    return dict(sorted(compte.items()))


def resume(verdict: dict[str, Any]) -> dict[str, Any]:
    """Ce que garde le registre d'entraînement : applicable, violations, structure tenue, par règle."""
    erreurs = verdict.get("erreurs", [])
    return {"applicable": verdict.get("applicable", False), "violations": len(erreurs),
            "structure_ok": not any(e.get("categorie") == "structure" for e in erreurs),
            "par_regle": par_regle(verdict)}


__all__ = ["MECANIQUES", "REGLES", "SESSION", "par_regle", "resume", "texte", "verifier_regles"]
