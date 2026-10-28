"""Relevé de la mémoire de la carte à chaque pas d'un entraînement de LLaMA-Factory (étape C2 du suivi).

Lancé par `lancer.py` avec le Python de LLaMA-Factory ; il n'importe rien de l'usine :

    python -P suivi_memoire.py <etape_N.yaml> <memoire.jsonl> [<plafond en Mio>]

C'est le même entraînement que `llamafactory-cli train <yaml>` sur une carte (`launcher.launch` appelle `run_exp`),
avec un plafond de mémoire pour PyTorch (`set_per_process_memory_fraction`, raison dans `lancer.py`) et une ligne
par pas :
- `occupe_mio` : la mémoire des tenseurs (`memory_allocated`) ;
- `reserve_mio` : ce que PyTorch garde de la carte (`memory_reserved`) ;
- `libre_en_morceaux_mio` : la part de la réserve en morceaux libres de blocs coupés (`inactive_split_bytes`) ;
- `reessais` : les demandes de mémoire qui ont dû vider la réserve avant d'aboutir (`num_alloc_retries`) ;
- les pics depuis le pas précédent.
Une réserve très au-dessus de l'occupation, en morceaux libres, dit que la mémoire se morcelle.
"""

import json
import sys
import time
from pathlib import Path


def main() -> None:
    import torch
    from llamafactory.train.tuner import run_exp
    from transformers import TrainerCallback

    yaml, sortie = sys.argv[1], Path(sys.argv[2])
    mio = 1 << 20
    if len(sys.argv) > 3:
        total = torch.cuda.get_device_properties(0).total_memory
        torch.cuda.set_per_process_memory_fraction(min(1.0, int(sys.argv[3]) * mio / total))

    class Releve(TrainerCallback):
        def __init__(self) -> None:
            self.debut = time.time()

        def on_step_end(self, args, state, control, **kwargs):
            stats = torch.cuda.memory_stats()
            ligne = {"pas": state.global_step, "t_s": round(time.time() - self.debut),
                     "occupe_mio": torch.cuda.memory_allocated() // mio,
                     "reserve_mio": torch.cuda.memory_reserved() // mio,
                     "libre_en_morceaux_mio": stats.get("inactive_split_bytes.all.current", 0) // mio,
                     "reessais": stats.get("num_alloc_retries", 0),
                     "pic_occupe_mio": torch.cuda.max_memory_allocated() // mio,
                     "pic_reserve_mio": torch.cuda.max_memory_reserved() // mio}
            with sortie.open("a", encoding="utf-8") as f:
                f.write(json.dumps(ligne) + "\n")
            torch.cuda.reset_peak_memory_stats()

    sys.argv = [sys.argv[0], yaml]
    run_exp(callbacks=[Releve()])


if __name__ == "__main__":
    from multiprocessing import freeze_support

    freeze_support()
    main()
