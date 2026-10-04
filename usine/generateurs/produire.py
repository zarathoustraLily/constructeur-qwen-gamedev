"""Production de toutes les tâches candidates, de façon reproductible (graine fixe).

    python -m usine.generateurs produire [--graine 1] [--sortie donnees/candidats] [--f1 40]
                                         [--sources reference survivor …]

Le dossier de sortie est vidé puis rempli : <sortie>/<compétence>/<id>/ au format commun.
Chaque projet source de usine/generateurs/sources.py passe par les générateurs, avec ses plafonds ;
les ids portent le nom de la source. Un rapport `production.json` liste les tâches écrites et les
cas écartés avec leur raison.
"""

from __future__ import annotations

import json
import shutil
import time
from pathlib import Path
from typing import Any

from usine.generateurs import aller_retour, inverse, masquage, mutation
from usine.generateurs.commun import Production
from usine.generateurs.sources import Source, par_nom


def _etapes(src: Source, sortie: Path, graine: int, nombre_f1: int, travailleurs: int):
    s, p = src.chemin, src.plafond
    etapes = [
        ("masquage K2", lambda: masquage.generer_k2(s, sortie, p("k2"), graine, src.ciblee)),
        ("masquage K1", lambda: masquage.generer_k1(s, sortie, p("k1"), graine)),
        ("aller-retour S1", lambda: aller_retour.generer_s1(s, sortie, p("s1"), graine, src.scenes_generees)),
        ("aller-retour S2", lambda: aller_retour.generer_s2(s, sortie, p("s2"), graine, src.scenes_generees)),
    ]
    if src.f1:
        etapes.append(("inverse F1", lambda: inverse.generer(s, sortie, graine, nombre_f1)))
    etapes.append(("mutation K3/D1", lambda: mutation.generer(s, sortie, graine, travailleurs, p("mutation"),
                                                              src.ciblee)))
    return etapes


def produire(sortie: Path, graine: int, nombre_f1: int = 40, travailleurs: int = 4, afficher=print,
             sources: list[str] | None = None) -> Production:
    sortie = Path(sortie)
    if sortie.exists():
        shutil.rmtree(sortie)
    sortie.mkdir(parents=True)
    total = Production()
    choisies = par_nom(sources)
    for src in choisies:
        if len(choisies) > 1:
            afficher(f"-- source {src.nom}")
        for nom, etape in _etapes(src, sortie, graine, nombre_f1, travailleurs):
            debut = time.monotonic()
            p = etape()
            afficher(f"{nom:<18} {len(p.taches):>4} tâches  {len(p.ecartes):>4} écartés  ({time.monotonic() - debut:.0f} s)")
            total.etendre(p)
    rapport: dict[str, Any] = {
        "graine": graine, "sources": [s.nom for s in choisies],
        "taches": sorted(str(d.relative_to(sortie).as_posix()) for d in total.taches),
        "ecartes": sorted(total.ecartes, key=lambda e: (e["generateur"], e["id"])),
    }
    (sortie / "production.json").write_text(json.dumps(rapport, ensure_ascii=False, indent=1) + "\n",
                                            encoding="utf-8", newline="\n")
    return total
