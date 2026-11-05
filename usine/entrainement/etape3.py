"""Préparer le dossier de l'étape 3 de l'entraînement, celle de la carte louée (décision 19.4 ; décision 22).

Décision 19.4 : « une époque sur les 3 000 sessions et environ 5 000 paires courtes tirées dans les deux paliers ».
Décision 22 : 600 sessions longues pour RunPod. Le dossier produit contient :
- les sessions longues des cours (`base_<cours>_sharegpt.jsonl` des livraisons), copiées telles quelles ;
- `courtes_etape_3.jsonl` : des paires tirées au hasard (graine fixe) dans `palier_1.jsonl` et `palier_2.jsonl` ;
- `images/` : les images de ces paires. Leurs chemins deviennent relatifs (`images/<famille>/…`), et LLaMA-Factory
  les lit depuis `dataset_dir`, car `media_dir` vaut `dataset_dir` par défaut
  (`llamafactory/hparams/data_args.py`, 0.9.5) ;
- `dataset_info.json`, et `etape_3.yaml` écrit avec les chemins de la carte louée (`--pod`).

Pourquoi un tirage et pas `max_samples` : LLaMA-Factory garde les N premiers exemples de chaque jeu
(`dataset.select(range(max_samples))`, `llamafactory/data/loader.py`), et non un échantillon au hasard.

Rien n'est lancé.

    python -m usine.entrainement etape3 [--sortie donnees/entrainement/etape_3] [--courtes 5000] [--graine 0]
                                        [--pod /workspace]
"""

from __future__ import annotations

import json
import random
import shutil
from pathlib import Path, PurePosixPath
from typing import Any

from usine.config import RACINE
from usine.entrainement import reglages

COURS = ("kart", "roguelike", "boss_action_rpg")
PALIERS = ("palier_1", "palier_2")


def _lignes(fichier: Path) -> list[str]:
    return [l for l in fichier.read_text(encoding="utf-8").splitlines() if l.strip()]


def preparer(sortie: Path, courtes: int = 5000, graine: int = 0, pod: str = "/workspace",
             racine: Path = RACINE) -> dict[str, Any]:
    """Écrit le dossier de l'étape 3 ; rend son bilan (nombres d'exemples et d'images)."""
    donnees = racine / "donnees"
    paires = (donnees / "paires").resolve()
    sortie.mkdir(parents=True, exist_ok=True)
    info: dict[str, Any] = {}
    bilan: dict[str, Any] = {"longues": {}, "courtes": 0, "courtes_avec_images": 0, "images": 0}
    for cours in COURS:
        source = donnees / "cours" / cours / "base" / "livraison" / f"base_{cours}_sharegpt.jsonl"
        if not source.is_file():
            raise FileNotFoundError(f"livraison absente : {source}")
        shutil.copyfile(source, sortie / source.name)
        info.update(reglages.info_jeu(f"base_{cours}", source.name, images=False))
        bilan["longues"][cours] = len(_lignes(source))
    tous: list[str] = []
    for palier in PALIERS:
        tous += _lignes(donnees / "entrainement" / f"{palier}.jsonl")
    tirees = random.Random(graine).sample(tous, min(courtes, len(tous)))
    sorties: list[str] = []
    for ligne in tirees:
        exemple = json.loads(ligne)
        if exemple.get("images"):
            relatives = []
            for chemin in exemple["images"]:
                image = Path(chemin).resolve()
                relatif = image.relative_to(paires)  # une image hors de donnees/paires lève ValueError
                cible = sortie / "images" / relatif
                if not cible.is_file():
                    cible.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(image, cible)
                    bilan["images"] += 1
                relatives.append(PurePosixPath("images", *relatif.parts).as_posix())
            exemple["images"] = relatives
            bilan["courtes_avec_images"] += 1
        sorties.append(json.dumps(exemple, ensure_ascii=False))
    (sortie / "courtes_etape_3.jsonl").write_text("\n".join(sorties) + "\n", encoding="utf-8")
    bilan["courtes"] = len(sorties)
    info.update(reglages.info_jeu("courtes_etape_3", "courtes_etape_3.jsonl", images=True))
    (sortie / "dataset_info.json").write_text(json.dumps(info, ensure_ascii=False, indent=2), encoding="utf-8")
    base = PurePosixPath(pod)
    r = reglages.reglages(3, base / "etape_3", ",".join(info), base / "lora_etape_3", base / "lora_etape_2")
    r["model_name_or_path"] = (base / "qwen38_27b").as_posix()
    (sortie / "etape_3.yaml").write_text(reglages.en_yaml(r), encoding="utf-8")
    bilan["jeux"] = list(info)
    return bilan
