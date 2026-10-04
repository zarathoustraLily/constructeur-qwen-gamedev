"""Production de toutes les tâches candidates, de façon reproductible (graine fixe).

    python -m usine.generateurs produire [--graine 1] [--sortie donnees/candidats] [--f1 40]

Le dossier de sortie est vidé puis rempli : <sortie>/<compétence>/<id>/ au format commun.
Un rapport `production.json` liste les tâches écrites et les cas écartés avec leur raison.
"""

from __future__ import annotations

import json
import shutil
import time
from pathlib import Path
from typing import Any

from usine.generateurs import aller_retour, inverse, masquage, mutation
from usine.generateurs.commun import SOURCE_REFERENCE, Production


def produire(sortie: Path, graine: int, source: Path = SOURCE_REFERENCE, nombre_f1: int = 40,
             travailleurs: int = 4, afficher=print) -> Production:
    sortie = Path(sortie)
    if sortie.exists():
        shutil.rmtree(sortie)
    sortie.mkdir(parents=True)
    total = Production()
    etapes = [
        ("masquage K2", lambda: masquage.generer_k2(source, sortie)),
        ("masquage K1", lambda: masquage.generer_k1(source, sortie)),
        ("aller-retour S1", lambda: aller_retour.generer_s1(source, sortie)),
        ("aller-retour S2", lambda: aller_retour.generer_s2(source, sortie)),
        ("inverse F1", lambda: inverse.generer(source, sortie, graine, nombre_f1)),
        ("mutation K3/D1", lambda: mutation.generer(source, sortie, graine, travailleurs)),
    ]
    for nom, etape in etapes:
        debut = time.monotonic()
        p = etape()
        afficher(f"{nom:<18} {len(p.taches):>4} tâches  {len(p.ecartes):>4} écartés  ({time.monotonic() - debut:.0f} s)")
        total.etendre(p)
    rapport: dict[str, Any] = {
        "graine": graine, "source": source.name,
        "taches": sorted(str(d.relative_to(sortie).as_posix()) for d in total.taches),
        "ecartes": sorted(total.ecartes, key=lambda e: (e["generateur"], e["id"])),
    }
    (sortie / "production.json").write_text(json.dumps(rapport, ensure_ascii=False, indent=1) + "\n",
                                            encoding="utf-8", newline="\n")
    return total
