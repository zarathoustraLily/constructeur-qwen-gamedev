"""Score de mutation : combien de mutants de la référence un jeu de tests tue.

C'est le critère de qualité des tests (C2) et une règle du portillon. Un mutant est « tué »
si le juge échoue sur le projet muté (n'importe quelle étape) ; il « survit » s'il passe.

- `score_mutation(projet, tests)` : tous les mutants des scripts et scènes du jeu (ou de
  `cibles`), éventuellement plafonnés par un tirage déterministe.
- `score_mutation_tache(dossier)` : mutants pris dans la zone que la référence change par
  rapport au départ (lignes ajoutées ou modifiées), jugés avec les tests cachés de la tâche.
  Un mutant qui survit là montre que les tests ne vérifient pas vraiment la réponse.

Les verdicts passent par le cache (usine.juge.cache).
"""

from __future__ import annotations

import difflib
import random
import shutil
import tempfile
from pathlib import Path
from typing import Any

from usine.generateurs.commun import ecrire_projet, lire_projet
from usine.generateurs.operateurs import Mutant, mutants_projet
from usine.juge import cache
from usine.juge.projet import ETAPES, IGNORES_COPIE
from usine.taches import lire_tache


def lignes_changees(avant: str | None, apres: str) -> set[int]:
    """Numéros (1-based) des lignes de `apres` ajoutées ou modifiées par rapport à `avant`."""
    b = apres.split("\n")
    if avant is None:
        return set(range(1, len(b) + 1))
    a = avant.split("\n")
    resultat: set[int] = set()
    for op, _, _, j1, j2 in difflib.SequenceMatcher(a=a, b=b, autojunk=False).get_opcodes():
        if op in ("replace", "insert"):
            resultat |= set(range(j1 + 1, j2 + 1))
    return resultat


def tirer(mutants: list[Mutant], maximum: int | None, graine: Any) -> list[Mutant]:
    if maximum is None or len(mutants) <= maximum:
        return mutants
    choisis = set(m.id for m in random.Random(str(graine)).sample(mutants, maximum))
    return [m for m in mutants if m.id in choisis]


def _juger(fichiers: dict[str, str], m: Mutant, tests: Path, etapes: list[str]) -> bool:
    """Vrai si le mutant est tué."""
    with tempfile.TemporaryDirectory(prefix="usine_mutant_") as tmp:
        mute = dict(fichiers)
        mute[m.fichier] = m.appliquer(fichiers[m.fichier])
        src = ecrire_projet(mute, Path(tmp) / "src")
        return not cache.juger(src, [], tests, etapes, repetition=1)["ok"]


def _resultat(mutants: list[Mutant], tues: list[bool]) -> dict[str, Any]:
    total = len(mutants)
    n = sum(tues)
    return {"total": total, "tues": n, "score": (n / total) if total else None,
            "survivants": [m.id for m, t in zip(mutants, tues) if not t]}


def score_mutation(projet: Path, tests: Path, cibles: dict[str, set[int] | None] | None = None,
                   maximum: int | None = None, graine: Any = 0, etapes: list[str] | None = None) -> dict[str, Any]:
    fichiers = lire_projet(projet)
    mutants = tirer(mutants_projet(fichiers, cibles), maximum, graine)
    tues = [_juger(fichiers, m, Path(tests), etapes or list(ETAPES)) for m in mutants]
    return _resultat(mutants, tues)


def score_mutation_tache(dossier: Path, maximum: int | None = 8, graine: Any = 0) -> dict[str, Any]:
    dossier = Path(dossier)
    tache = lire_tache(dossier)
    etapes = tache.get("juge", {}).get("etapes", list(ETAPES))
    with tempfile.TemporaryDirectory(prefix="usine_compose_") as tmp:
        compose = Path(tmp) / "p"
        shutil.copytree(dossier / "depart", compose, ignore=IGNORES_COPIE)
        shutil.copytree(dossier / "reference", compose, dirs_exist_ok=True, ignore=IGNORES_COPIE)
        fichiers = lire_projet(compose)
    depart = lire_projet(dossier / "depart")
    cibles = {}
    for f in sorted((dossier / "reference").rglob("*")):
        rel = f.relative_to(dossier / "reference").as_posix()
        if f.is_file() and rel.endswith((".gd", ".tscn")) and not rel.startswith("tests/"):
            cibles[rel] = lignes_changees(depart.get(rel), fichiers[rel])
    mutants = tirer(mutants_projet(fichiers, cibles), maximum, f"{graine}:{tache['id']}")
    tues = [_juger(fichiers, m, dossier / "tests_caches", etapes) for m in mutants]
    return _resultat(mutants, tues)


def main(argv: list[str] | None = None) -> int:
    """python -m usine.generateurs.mutants <projet> <dossier_tests> [--max N] [--graine G]"""
    import argparse
    import json
    import sys

    sys.stdout.reconfigure(encoding="utf-8")
    p = argparse.ArgumentParser(prog="python -m usine.generateurs.mutants",
                                description="Score de mutation d'un dossier de tests sur un projet.")
    p.add_argument("projet", type=Path)
    p.add_argument("tests", type=Path, help="dossier de tests (copié dans res://tests_juge/)")
    p.add_argument("--max", type=int, default=None)
    p.add_argument("--graine", default="0")
    a = p.parse_args(argv)
    r = score_mutation(a.projet, a.tests, maximum=a.max, graine=a.graine)
    print(json.dumps(r, ensure_ascii=False, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
