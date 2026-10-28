"""Lancer un entraînement de LLaMA-Factory sur la machine et en garder la trace (étape C2 du suivi).

Ne se lance que sur commande, avec l'accord de laurent (section 1 : rien ne part sur son PC sans lui ; accord du
2026-10-28 pour l'étape 1 : « vas sy he te l'aisse l'ordinateur »). Avant de partir, on vérifie que la carte est
libre (aucun llama-server : un seul processus peut tenir les 32 Go). Le processus lancé est le seul qu'on arrête
(règle 8, par son PID).

L'entraînement passe par `suivi_memoire.py`, lancé avec le Python de LLaMA-Factory : le même que
`llamafactory-cli train`, avec un relevé de la mémoire de PyTorch à chaque pas et un plafond de mémoire.

Pourquoi un plafond (2026-10-28) : PyTorch ne vide sa réserve qu'après un refus de mémoire (`num_alloc_retries` :
« failed cudaMalloc calls that result in a cache flush and retry », `torch/cuda/memory.py`). Sous Windows, la carte
pleine ne refuse rien : le pilote prête la mémoire du PC, et la réserve grossit sans fin. Sur des exemples de
longueurs toutes différentes, elle a passé 2 582 Mio en mémoire partagée au pas 3 (pas de 45 à 510 s, puis arrêt du
pilote au pas 44 du premier essai) ; avec `PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:256,
garbage_collection_threshold:0.8`, 14 760 Mio avant la fin du pas 1. `set_per_process_memory_fraction` fait refuser
la mémoire par PyTorch lui-même au plafond : il vide alors sa réserve et réessaie. Plafond : ce qui est libre au
départ, moins `MARGE_MIO` pour le contexte CUDA et les applications ouvertes.

Écrit dans le dossier de sortie du LoRA : `journal.txt` (sortie de LLaMA-Factory), `memoire.jsonl` (le relevé),
`bilan.json` (code, durée, pic de mémoire de la carte relevé toutes les 15 s par nvidia-smi, résumé du relevé, pertes
journalisées).

    python -m usine.entrainement lancer --yaml <etape_N.yaml> [--cli <llamafactory-cli.exe>]
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import time
from pathlib import Path
from typing import Any

from usine import config as cfg

CLI_PAR_DEFAUT = "G:/llm_lora_trainer/venv/Scripts/llamafactory-cli.exe"
INTERVALLE_S = 15
MEMOIRE_LIBRE_MIN_MIO = 26_000  # l'essai de mémoire a pris 26,4 Go d'entraînement pour 2 048 jetons
MARGE_MIO = 2_000
SUIVI = Path(__file__).with_name("suivi_memoire.py")


def cli(config: dict[str, Any] | None = None) -> str:
    config = cfg.charger_config() if config is None else config
    return str(config.get("entrainement", {}).get("llamafactory") or CLI_PAR_DEFAUT)


def memoire_carte() -> tuple[int, int] | None:
    """(Mio utilisés, Mio en tout) de la première carte, ou None sans nvidia-smi."""
    try:
        s = subprocess.run(["nvidia-smi", "--query-gpu=memory.used,memory.total", "--format=csv,noheader,nounits"],
                           capture_output=True, text=True, timeout=30)
    except (OSError, subprocess.TimeoutExpired):
        return None
    m = re.match(r"\s*(\d+)\s*,\s*(\d+)", s.stdout)
    return (int(m[1]), int(m[2])) if m else None


def python_de(executable: str) -> str:
    """Le Python de l'environnement de LLaMA-Factory, à côté de `llamafactory-cli`."""
    return str(Path(executable).with_name("python.exe" if os.name == "nt" else "python"))


def resume_memoire(fichier: Path) -> dict[str, Any] | None:
    """Les maxima du relevé de `suivi_memoire.py`."""
    if not fichier.is_file():
        return None
    lignes = [json.loads(l) for l in fichier.read_text(encoding="utf-8").splitlines() if l.strip()]
    if not lignes:
        return None
    return {"pas": len(lignes), **{f"max_{k}": max(l[k] for l in lignes)
                                  for k in ("pic_occupe_mio", "pic_reserve_mio", "libre_en_morceaux_mio", "reessais")}}


def sortie_du_yaml(yaml: Path) -> Path:
    m = re.search(r"^output_dir:\s*\"?([^\"\n]+)\"?\s*$", yaml.read_text(encoding="utf-8"), re.M)
    if not m:
        raise ValueError(f"output_dir absent de {yaml}")
    return Path(m[1])


def pertes(journal: str) -> list[dict[str, float]]:
    """Les lignes {'loss': …, 'epoch': …} que LLaMA-Factory écrit tous les `logging_steps` pas."""
    sortie = []
    for m in re.finditer(r"\{'loss': '?([\d.]+)'?.*?'epoch': '?([\d.]+)'?", journal):
        sortie.append({"perte": float(m[1]), "epoque": float(m[2])})
    return sortie


def lancer(yaml: Path, executable: str | None = None) -> dict[str, Any]:
    yaml = yaml.resolve()
    sortie = sortie_du_yaml(yaml)
    sortie.mkdir(parents=True, exist_ok=True)
    avant = memoire_carte()
    if avant and avant[1] - avant[0] < MEMOIRE_LIBRE_MIN_MIO:
        raise RuntimeError(f"carte occupée : {avant[0]} Mio pris sur {avant[1]} (llama-server lancé ?) ; rien n'est lancé")
    journal = sortie / "journal.txt"
    env = dict(os.environ, PYTHONUTF8="1", PYTHONIOENCODING="utf-8")
    limite = avant[1] - avant[0] - MARGE_MIO if avant else None
    # -P : le dossier du script n'entre pas dans le chemin d'import de LLaMA-Factory.
    commande = [python_de(executable or cli()), "-P", str(SUIVI), str(yaml), str(sortie / "memoire.jsonl")]
    if limite:
        commande.append(str(limite))
    debut = time.time()
    pic = avant[0] if avant else 0
    # À la suite : après un arrêt, LLaMA-Factory reprend depuis le dernier `checkpoint-N` et le journal se poursuit.
    with journal.open("a", encoding="utf-8", errors="replace") as f:
        proc = subprocess.Popen(commande, stdout=f, stderr=subprocess.STDOUT, env=env, cwd=str(sortie))
        (sortie / "pid.txt").write_text(str(proc.pid), encoding="utf-8")
        while proc.poll() is None:
            time.sleep(INTERVALLE_S)
            m = memoire_carte()
            if m:
                pic = max(pic, m[0])
    texte = journal.read_text(encoding="utf-8", errors="replace")
    bilan = {"yaml": str(yaml), "code": proc.returncode, "duree_s": round(time.time() - debut),
             "memoire_avant_mio": avant[0] if avant else None, "pic_mio": pic, "carte_mio": avant[1] if avant else None,
             "plafond_pytorch_mio": limite, "releve": resume_memoire(sortie / "memoire.jsonl"),
             "pertes": pertes(texte), "manque_memoire": "OutOfMemoryError" in texte or "CUDA out of memory" in texte,
             "adaptateur": (sortie / "adapter_model.safetensors").is_file()}
    (sortie / "bilan.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan
