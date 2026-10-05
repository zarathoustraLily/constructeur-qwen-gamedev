"""Production de toutes les tâches candidates, de façon reproductible (graine fixe).

    python -m usine.generateurs produire [--graine 1] [--sortie donnees/candidats] [--f1 40] [--e 120]
                                         [--sources reference survivor …] [--competences E …]

Le dossier de sortie est vidé puis rempli : <sortie>/<compétence>/<id>/ au format commun.
Chaque projet source de usine/generateurs/sources.py passe par les générateurs, avec ses plafonds ;
les ids portent le nom de la source. La compétence E (optimisation stricte) ne lit aucune source :
ses paires de jeux sont écrites par usine/generateurs/efficience.py. `competences` restreint la
production à certaines compétences (les autres générateurs ne tournent pas). Un rapport `production.json` liste les tâches écrites et les
cas écartés avec leur raison.
"""

from __future__ import annotations

import json
import shutil
import time
from pathlib import Path
from typing import Any

from usine.generateurs import aller_retour, efficience, inverse, masquage, mutation
from usine.generateurs.commun import Production
from usine.generateurs.sources import Source, par_nom


def _etapes(src: Source, sortie: Path, graine: int, nombre_f1: int, travailleurs: int):
    """[(nom, compétences produites, étape)]."""
    s, p = src.chemin, src.plafond
    etapes = [
        ("masquage K2", {"K2"}, lambda: masquage.generer_k2(s, sortie, p("k2"), graine, src.ciblee)),
        ("masquage K1", {"K1"}, lambda: masquage.generer_k1(s, sortie, p("k1"), graine)),
        ("aller-retour S1", {"S1"}, lambda: aller_retour.generer_s1(s, sortie, p("s1"), graine, src.scenes_generees)),
        ("aller-retour S2", {"S2"}, lambda: aller_retour.generer_s2(s, sortie, p("s2"), graine, src.scenes_generees)),
    ]
    if src.f1:
        etapes.append(("inverse F1", {"F1"}, lambda: inverse.generer(s, sortie, graine, nombre_f1)))
    etapes.append(("mutation K3/D1", {"K3", "D1"},
                   lambda: mutation.generer(s, sortie, graine, travailleurs, p("mutation"), src.ciblee)))
    return etapes


def produire(sortie: Path, graine: int, nombre_f1: int = 40, travailleurs: int = 4, afficher=print,
             sources: list[str] | None = None, competences: list[str] | None = None,
             nombre_e: int = efficience.NOMBRE_DEFAUT) -> Production:
    sortie = Path(sortie)
    if sortie.exists():
        shutil.rmtree(sortie)
    sortie.mkdir(parents=True)
    total = Production()
    voulues = set(competences) if competences else None
    choisies = par_nom(sources)
    lues: list[str] = []

    def lancer(nom: str, etape) -> None:
        debut = time.monotonic()
        p = etape()
        afficher(f"{nom:<18} {len(p.taches):>4} tâches  {len(p.ecartes):>4} écartés  ({time.monotonic() - debut:.0f} s)")
        total.etendre(p)

    for src in choisies:
        etapes = [(n, e) for n, comps, e in _etapes(src, sortie, graine, nombre_f1, travailleurs)
                  if voulues is None or comps & voulues]
        if etapes:
            lues.append(src.nom)
        if etapes and len(choisies) > 1:
            afficher(f"-- source {src.nom}")
        for nom, etape in etapes:
            lancer(nom, etape)
    if voulues is None or efficience.COMPETENCE in voulues:
        if len(choisies) > 1 or voulues:
            afficher("-- sans source (jeux écrits par le générateur)")
        lancer("efficience E", lambda: efficience.generer(sortie, graine, nombre_e, travailleurs))
    doubles = sorted({d.name for d in total.taches if total.taches.count(d) > 1})
    if doubles:
        # Deux tâches du même id : la seconde a écrasé la première. À corriger dans le générateur.
        raise ValueError(f"ids de tâches en double (générateur à corriger) : {', '.join(doubles)}")
    rapport: dict[str, Any] = {
        "graine": graine, "sources": lues, "competences": sorted(voulues) if voulues else None,
        "taches": sorted(str(d.relative_to(sortie).as_posix()) for d in total.taches),
        "ecartes": sorted(total.ecartes, key=lambda e: (e["generateur"], e["id"])),
    }
    (sortie / "production.json").write_text(json.dumps(rapport, ensure_ascii=False, indent=1) + "\n",
                                            encoding="utf-8", newline="\n")
    return total
