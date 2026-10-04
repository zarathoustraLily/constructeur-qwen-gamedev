"""Cache des verdicts, indexé par le contenu exact de ce qui est jugé.

Une clé = SHA-256 de : fichiers du projet composé (source + superpositions), tests cachés,
étapes, filtre, version de Godot, et numéro de répétition. Deux jugements de mêmes octets
partagent donc leur verdict ; les répétitions (« 3 fois sur 3 ») restent des exécutions
distinctes, chacune sous sa propre clé.

Exclus de la clé : les journaux fournis à l'agent à la racine du projet (`journal.txt`,
`journal_tests.json`), que le juge ne lit jamais.

Le cache vit dans donnees/cache_juge/ (un fichier JSON par clé, écriture atomique).
"""

from __future__ import annotations

import hashlib
import json
import os
import tempfile
from pathlib import Path
from typing import Any, Iterable

from usine import config as cfg
from usine.juge.projet import DOSSIER_TESTS_JUGE, ETAPES, juger_projet

JOURNAUX_AGENT = {"journal.txt", "journal_tests.json"}
_IGNORES = {".godot", "reports", "__pycache__", ".import", ".usine_rapports"}


def _empreintes(racine: Path, prefixe: str, ignorer_journaux: bool) -> dict[str, str]:
    resultat: dict[str, str] = {}
    if racine is None or not Path(racine).is_dir():
        return resultat
    racine = Path(racine)
    for f in sorted(racine.rglob("*")):
        if not f.is_file():
            continue
        rel = f.relative_to(racine)
        if _IGNORES & set(rel.parts) or f.suffix == ".uid":
            continue
        if ignorer_journaux and len(rel.parts) == 1 and rel.name in JOURNAUX_AGENT:
            continue
        resultat[prefixe + rel.as_posix()] = hashlib.sha256(f.read_bytes()).hexdigest()
    return resultat


def cle_jugement(projet: Path, superpositions: Iterable[Path] = (), tests_caches: Path | None = None,
                 etapes: Iterable[str] = ETAPES, filtre: str | None = None, repetition: int = 1) -> str:
    fichiers = _empreintes(projet, "", True)
    for sup in superpositions:
        fichiers.update(_empreintes(sup, "", True))
    fichiers.update(_empreintes(tests_caches, f"{DOSSIER_TESTS_JUGE}/", False) if tests_caches else {})
    h = hashlib.sha256()
    h.update(json.dumps({"fichiers": fichiers, "etapes": [e for e in ETAPES if e in set(etapes)],
                         "filtre": filtre, "godot": cfg.version_godot(), "rep": repetition},
                        sort_keys=True).encode("utf-8"))
    return h.hexdigest()


def dossier_cache() -> Path:
    return cfg.dossier_donnees() / "cache_juge"


def lire(cle: str) -> dict[str, Any] | None:
    chemin = dossier_cache() / cle[:2] / f"{cle}.json"
    if not chemin.is_file():
        return None
    return json.loads(chemin.read_text(encoding="utf-8"))


def ecrire(cle: str, verdict: dict[str, Any]) -> None:
    dossier = dossier_cache() / cle[:2]
    dossier.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=dossier, suffix=".tmp")
    with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as f:
        json.dump(verdict, f, ensure_ascii=False)
    os.replace(tmp, dossier / f"{cle}.json")


def juger(projet: Path, superpositions: Iterable[Path] = (), tests_caches: Path | None = None,
          etapes: Iterable[str] = ETAPES, repetition: int = 1, utiliser_cache: bool = True) -> dict[str, Any]:
    """Comme `juger_projet` (filtre = tests cachés seulement), avec cache. Ajoute « depuis_cache »."""
    superpositions = list(superpositions)
    etapes = list(etapes)
    filtre = f"res://{DOSSIER_TESTS_JUGE}" if tests_caches else None
    cle = cle_jugement(projet, superpositions, tests_caches, etapes, filtre, repetition)
    if utiliser_cache:
        connu = lire(cle)
        if connu is not None:
            connu["depuis_cache"] = True
            return connu
    verdict = juger_projet(projet, filtre, etapes, superpositions, tests_caches)
    ecrire(cle, verdict)
    verdict = dict(verdict)
    verdict["depuis_cache"] = False
    return verdict
