"""Gel des jeux de test : tirage reproductible, manifeste, exclusion partout.

Tirage : pour chaque compétence, parmi les tâches qualifiées (règles 1 à 3 du portillon),
triées par id, `random.Random(f"gel:{graine}:{competence}")` tire
min(cible, ⌊part_max × disponibles⌋) tâches. La part maximale (0,5 par défaut) garde des
tâches pour l'entraînement tant que le projet source est petit : la cible de 50 n'est atteinte
qu'à partir de 100 tâches qualifiées dans la compétence.

Le manifeste (donnees/geles/manifeste.json) porte, par tâche gelée : id, empreinte (SHA-256),
fragments de la réponse et de la consigne. Il ne se réécrit pas : une fois créé, le gel est
réutilisé tel quel (règle 4 : gelés avant tout entraînement). `completer=True` ajoute des tâches
aux compétences sous la cible, sans jamais en retirer — à faire avant le premier entraînement.
"""

from __future__ import annotations

import json
import random
import shutil
from pathlib import Path
from typing import Any

from usine.portillon.dedoublonnage import K_FRAGMENT, signature_tache
from usine.taches import lire_tache

VERSION_MANIFESTE = 1


def chemin_manifeste(racine: Path) -> Path:
    return Path(racine) / "geles" / "manifeste.json"


def lire_manifeste(racine: Path) -> dict[str, Any] | None:
    chemin = chemin_manifeste(racine)
    if not chemin.is_file():
        return None
    return json.loads(chemin.read_text(encoding="utf-8"))


def _ecrire_json(chemin: Path, objet: Any) -> None:
    chemin.parent.mkdir(parents=True, exist_ok=True)
    chemin.write_text(json.dumps(objet, ensure_ascii=False, indent=1, sort_keys=True) + "\n", encoding="utf-8",
                      newline="\n")


def tirer(qualifiees: dict[str, list[Path]], graine: int, cible: int, part_max: float,
          deja: dict[str, list[str]] | None = None) -> dict[str, list[Path]]:
    """{compétence: dossiers tirés}, en complétant éventuellement un gel existant (`deja` : ids)."""
    deja = deja or {}
    tirage: dict[str, list[Path]] = {}
    for comp in sorted(qualifiees):
        dossiers = sorted(qualifiees[comp], key=lambda d: d.name)
        presents = set(deja.get(comp, []))
        nombre = min(cible, int(part_max * (len(dossiers) + len(presents)))) - len(presents)
        restants = [d for d in dossiers if d.name not in presents]
        if nombre <= 0 or not restants:
            tirage[comp] = []
            continue
        rng = random.Random(f"gel:{graine}:{comp}:{len(presents)}")
        choisis = set(d.name for d in rng.sample(restants, min(nombre, len(restants))))
        tirage[comp] = [d for d in restants if d.name in choisis]
    return tirage


def geler(racine: Path, qualifiees: dict[str, list[Path]], graine: int, cible: int = 50, part_max: float = 0.5,
          completer: bool = False) -> dict[str, Any]:
    """Crée (ou réutilise, ou complète) le manifeste et copie les tâches gelées dans geles/<C>/<id>/."""
    racine = Path(racine)
    manifeste = lire_manifeste(racine)
    if manifeste is not None and not completer:
        return manifeste
    if manifeste is None:
        manifeste = {"version": VERSION_MANIFESTE, "graine": graine, "cible_par_competence": cible,
                     "part_max": part_max, "k_fragment": K_FRAGMENT, "competences": {}}
    deja = {c: [t["id"] for t in v["taches"]] for c, v in manifeste["competences"].items()}
    tirage = tirer(qualifiees, graine, cible, part_max, deja)
    for comp, dossiers in tirage.items():
        entree = manifeste["competences"].setdefault(comp, {"taches": []})
        for d in dossiers:
            sig = signature_tache(d)
            entree["taches"].append({"id": sig["id"], "empreinte": sig["empreinte"], "fragments": sig["fragments"],
                                     "fragments_consigne": sig["fragments_consigne"]})
            cible_dossier = racine / "geles" / comp / d.name
            if cible_dossier.exists():
                shutil.rmtree(cible_dossier)
            shutil.copytree(d, cible_dossier)
            tache = lire_tache(cible_dossier)
            tache["gelee"] = True
            _ecrire_json(cible_dossier / "tache.json", tache)
        entree["taches"].sort(key=lambda t: t["id"])
        entree["disponibles_au_tirage"] = len(qualifiees.get(comp, [])) + len(deja.get(comp, []))
        entree["complet"] = len(entree["taches"]) >= cible
    _ecrire_json(chemin_manifeste(racine), manifeste)
    return manifeste
