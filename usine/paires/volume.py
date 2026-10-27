"""Génération en volume des paires courtes sur la machine (étapes B9 et D5 du suivi ; accord de laurent du
2026-10-27 : « ok pour tout »).

Les familles passent l'une après l'autre : elles matérialisent les mêmes projets d'étape (`sess_<cours>_<n>`), deux à
la fois se marcheraient dessus. Une famille qui plante est notée au journal, la suivante part quand même. À la fin :
les lectures (B4, tirées des sorties de B1 à B3), puis l'assemblage des deux paliers.

    python -m usine.paires volume [--seulement creation,execution,...]
"""

from __future__ import annotations

import json
import time
import traceback
from pathlib import Path
from typing import Any, Callable

from usine import config as cfg

COURS = ("kart", "roguelike", "batiments_proceduraux")
# (famille, fautes ou fonctions tirées par étape) : assez pour épuiser les candidats de chaque étape (dédoublonnés
# d'une étape à l'autre), sans dépasser les cibles du PLAN.
PAR_ETAPE = {"creation": 30, "execution": 30, "compilation": 150, "shader": 60}
NIVEAUX = {"timing": (13, 300), "editeur": (12, 300)}   # (jeux ou niveaux au plus, paires visées)
ORDRE = ("creation", "execution", "compilation", "shader", "timing", "editeur")


def _familles(nom: str, cours: tuple[str, ...] = COURS) -> list[tuple[str, Callable[[], dict[str, Any]]]]:
    if nom in ("compilation", "shader"):
        from usine.paires.compilation import generer
        return [(f"{nom} {c}", lambda c=c: generer(c, PAR_ETAPE[nom], famille=nom)) for c in cours]
    if nom == "execution":
        from usine.paires.execution import generer
        return [(f"execution {c}", lambda c=c: generer(c, PAR_ETAPE[nom])) for c in cours]
    if nom == "creation":
        from usine.paires.creation import generer
        return [(f"creation {c}", lambda c=c: generer(c, PAR_ETAPE[nom])) for c in cours]
    if nom == "timing":
        from usine.paires.timing import generer
        return [("timing", lambda: generer(NIVEAUX[nom][0], cible=NIVEAUX[nom][1]))]
    if nom == "editeur":
        from usine.paires.editeur import generer
        return [("editeur", lambda: generer(NIVEAUX[nom][0], cible=NIVEAUX[nom][1]))]
    raise ValueError(nom)


def lancer(seulement: list[str] | None = None, journal_fichier: Path | None = None,
           cours: list[str] | None = None) -> dict[str, Any]:
    chemin = journal_fichier or Path(cfg.dossier_donnees()) / "paires" / "volume.log"
    chemin.parent.mkdir(parents=True, exist_ok=True)

    def journal(texte: str) -> None:
        ligne = f"{time.strftime('%Y-%m-%d %H:%M:%S')}  {texte}"
        print(ligne, flush=True)
        with chemin.open("a", encoding="utf-8") as f:
            f.write(ligne + "\n")

    bilan: dict[str, Any] = {}
    for nom in seulement or ORDRE:
        for etiquette, fonction in _familles(nom, tuple(cours or COURS)):
            debut = time.time()
            journal(f"début : {etiquette}")
            try:
                b = fonction()
                resume = {k: v for k, v in b.items() if k != "rejets"}
                resume["rejets"] = len(b.get("rejets", []))
                bilan[etiquette] = resume
                journal(f"fin : {etiquette} en {round((time.time() - debut) / 60, 1)} min : "
                        f"{json.dumps(resume, ensure_ascii=False)}")
            except Exception:  # noqa: BLE001 — une famille qui plante n'arrête pas les autres
                bilan[etiquette] = {"erreur": traceback.format_exc(limit=5)}
                journal(f"ÉCHEC : {etiquette}\n{bilan[etiquette]['erreur']}")
    from usine.paires.assembler import assembler
    from usine.paires.lecture import generer as lectures
    bilan["lecture"] = {k: v for k, v in lectures(journal=journal).items()}
    journal(f"lectures : {bilan['lecture']['paires']}")
    from usine.paires.rag import generer as rag
    bilan["rag"] = {k: v for k, v in rag(journal=journal).items() if k != "rejets"}
    journal(f"paires RAG : {bilan['rag']['paires']}")
    for n in (1, 2):
        c = assembler(n, journal=journal)
        bilan[f"palier_{n}"] = {k: c[k] for k in ("paires", "rejets", "trous", "jetons", "duree_estimee_5090_h",
                                                  "problemes", "par_famille", "par_type")}
    (chemin.parent / "volume_bilan.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    journal("terminé")
    return bilan
