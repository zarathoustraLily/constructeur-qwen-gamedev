"""Réglages de LLaMA-Factory pour les trois étapes d'entraînement (étape C1 du suivi ; décision 19).

- Étape 1 (5090) : une époque sur les paires du palier 1 (1 024 jetons au plus).
- Étape 2 (5090) : une époque sur les paliers 1 et 2 (2 048 au plus), en reprenant le LoRA de l'étape 1.
- Étape 3 (carte louée) : les sessions au format d'OpenCode et des paires courtes tirées des deux paliers, en
  reprenant le LoRA de l'étape 2 ; `cutoff_len` 32 768 (règle 7.5).

Bases mesurées sur la 5090 (essais de mémoire du 2026-10-22, `donnees/essais/`, ETAT) : QLoRA rang 16, 4 bits,
`template: qwen3_5`, `enable_thinking: false` (règle 7.6), une paire de 2 043 jetons ou de 5 images en 640 × 360 par
pas : pic de 30 à 32 Go sur 32,6, 266 à 284 jetons/s. Donc un exemple par pas ; le lot effectif vient de
l'accumulation. La tour de vision et le projecteur restent gelés. `image_max_pixels` garde les images de l'éditeur en
1 280 × 720 (921 600 pixels) : LLaMA-Factory réduit toute image plus grande, et le compte des jetons d'images des paires
(880 pour 1 280 × 720) ne vaudrait plus.

Ce module écrit les fichiers ; `lancer.py` démarre l'entraînement, sur commande et avec l'accord de laurent.

    python -m usine.entrainement reglages --etape 1 --jeu <dossier du jeu> [--sortie <dossier>] [--reprise <LoRA>]
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

MODELE = "G:/llm_lora_trainer/qwen38_27b"
CUTOFF = {1: 1024, 2: 2048, 3: 32768}
JETONS_PAR_SECONDE_5090 = 266   # mesuré (essai de mémoire, 2 043 jetons par pas)
IMAGE_MAX_PIXELS = 1280 * 720

COMMUN: dict[str, Any] = {
    "model_name_or_path": MODELE,
    "quantization_bit": 4,
    "trust_remote_code": True,
    "stage": "sft",
    "do_train": True,
    "finetuning_type": "lora",
    "lora_rank": 16,
    "lora_alpha": 32,
    "lora_dropout": 0.05,
    "lora_target": "all",
    "freeze_vision_tower": True,
    "freeze_multi_modal_projector": True,
    "image_max_pixels": IMAGE_MAX_PIXELS,
    "template": "qwen3_5",
    "enable_thinking": False,
    "overwrite_cache": True,
    "preprocessing_num_workers": 1,  # comme les essais de mémoire : sous Windows, plusieurs processus risquent de bloquer
    "per_device_train_batch_size": 1,
    "gradient_accumulation_steps": 16,
    "learning_rate": 1.0e-4,
    "num_train_epochs": 1.0,
    "lr_scheduler_type": "cosine",
    "warmup_ratio": 0.03,
    "bf16": True,
    "logging_steps": 5,
    "save_strategy": "steps",
    # Tous les 10 pas : le 2026-10-28, un arrêt du pilote (TDR) au pas 44 sur 99 a perdu 6 h faute de sauvegarde ;
    # LLaMA-Factory reprend seul depuis le dernier `checkpoint-N` du dossier de sortie.
    "save_steps": 10,
    "save_total_limit": 2,
    "report_to": "none",
    "overwrite_output_dir": False,
}


def reglages(etape: int, jeu: Path, nom_jeu: str, sortie: Path, reprise: Path | None = None) -> dict[str, Any]:
    if etape not in CUTOFF:
        raise ValueError(f"étape inconnue : {etape} (1, 2 ou 3)")
    r = dict(COMMUN)
    r.update({"dataset": nom_jeu, "dataset_dir": jeu.as_posix(), "cutoff_len": CUTOFF[etape],
              "output_dir": sortie.as_posix()})
    if reprise is not None:
        r["adapter_name_or_path"] = reprise.as_posix()
    if etape == 3:
        # Carte louée : plus de mémoire, des exemples longs ; le lot effectif reste de 16 exemples.
        r["preprocessing_num_workers"] = 8
    return r


def _valeur(v: Any) -> str:
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    texte = str(v)
    return json.dumps(texte) if any(c in texte for c in ":#{}[],&*?|<>=!%@`'\"") or texte != texte.strip() else texte


def en_yaml(r: dict[str, Any]) -> str:
    """Un YAML plat (clés et scalaires seulement), sans dépendance."""
    return "".join(f"{k}: {_valeur(v)}\n" for k, v in r.items())


def info_jeu(nom: str, fichier: str, images: bool) -> dict[str, Any]:
    """L'entrée de `dataset_info.json` pour un jeu au format sharegpt (`usine.paires.format.vers_llamafactory`)."""
    colonnes = {"messages": "conversations", "system": "system"}
    if images:
        colonnes["images"] = "images"
    return {nom: {"file_name": fichier, "formatting": "sharegpt", "columns": colonnes,
                  "tags": {"role_tag": "from", "content_tag": "value", "user_tag": "human", "assistant_tag": "gpt"}}}


def duree_estimee_h(jetons: int, debit: float = JETONS_PAR_SECONDE_5090) -> float:
    """Heures d'entraînement pour une époque, au débit mesuré sur la 5090."""
    return round(jetons / debit / 3600, 1)


def ecrire(etape: int, jeu: Path, nom_jeu: str, sortie: Path, reprise: Path | None = None) -> Path:
    chemin = jeu / f"etape_{etape}.yaml"
    chemin.write_text(en_yaml(reglages(etape, jeu, nom_jeu, sortie, reprise)), encoding="utf-8")
    return chemin
