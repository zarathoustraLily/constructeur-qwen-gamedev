"""Un tour RFT : essais → filtre → export, avec reprise après coupure.

<sortie>/
  registre.csv      une ligne par essai (tache_id, competence, essai, ok, etape, longueur, duree_s,
                    session) ; réécrit de façon atomique (fichier temporaire puis remplacement)
                    après CHAQUE tâche. Une tâche présente avec ses N essais n'est jamais refaite ;
                    une tâche coupée en cours est refaite en entier (ses sessions sont réécrites,
                    rien n'est compté deux fois).
  sessions/<tache_id>/essai_<n>.jsonl
  retenus.csv       la solution retenue de chaque tâche réussie (filtre.py)
  a_refaire.txt     les tâches jamais réussies : entrée du tour suivant (--depuis)
  acquises.txt      les tâches réussies plus de maxi_reussites fois sur N : non exportées
  export/           données et configurations d'entraînement (export.py)

Les tâches viennent de donnees/taches (acceptées par le portillon, déjà dédoublonnées du gel).
Garde de la règle 4 : une tâche gelée (id ou empreinte du manifeste) n'est jamais essayée.
"""

from __future__ import annotations

import csv
import io
import json
import time
from pathlib import Path
from typing import Any, Callable, Iterable

from usine.capture.enregistreur import _ecrire_atomique
from usine.mesure.client import Reponse, completer
from usine.rft import export, filtre
from usine.rft.essais import Essai, ReglagesRft, essayer

COLONNES = ("tache_id", "competence", "essai", "ok", "etape", "longueur", "duree_s", "session")


def lire_registre(chemin: Path) -> list[dict[str, Any]]:
    if not Path(chemin).is_file():
        return []
    with Path(chemin).open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def ecrire_registre(chemin: Path, lignes: Iterable[dict[str, Any]]) -> None:
    tampon = io.StringIO()
    w = csv.DictWriter(tampon, fieldnames=COLONNES, lineterminator="\n")
    w.writeheader()
    for l in sorted(lignes, key=lambda l: (l["tache_id"], int(l["essai"]))):
        w.writerow({k: l[k] for k in COLONNES})
    _ecrire_atomique(Path(chemin), tampon.getvalue())


def _ligne(e: Essai) -> dict[str, Any]:
    return {"tache_id": e.tache_id, "competence": e.competence, "essai": e.essai, "ok": e.ok, "etape": e.etape,
            "longueur": e.longueur, "duree_s": e.duree_s, "session": e.session}


def selectionner(racine: Path, competences: Iterable[str] | None = None, depuis: Path | None = None,
                 limite: int | None = None, exclusion=None) -> list[Path]:
    """Tâches à essayer : celles de `racine`, filtrées (compétences, liste a_refaire, limite par
    compétence) ; une tâche gelée est refusée (règle 4)."""
    from usine.taches import lire_tache, lister_taches
    voulues = set(competences) if competences else None
    ids = None
    if depuis is not None:
        ids = {l.strip() for l in Path(depuis).read_text(encoding="utf-8").splitlines() if l.strip()}
    vus: dict[str, int] = {}
    choisies = []
    for dossier in lister_taches(racine):
        tache = lire_tache(dossier)
        if voulues is not None and tache["competence"] not in voulues:
            continue
        if ids is not None and tache["id"] not in ids:
            continue
        if exclusion is not None and exclusion.session_exclue({"tache_id": tache["id"], "empreinte": tache["empreinte"]}):
            raise ValueError(f"tâche gelée dans les tâches d'entraînement : {tache['id']} (règle 4)")
        vus[tache["competence"]] = vus.get(tache["competence"], 0) + 1
        if limite and vus[tache["competence"]] > limite:
            continue
        choisies.append(dossier)
    return choisies


def tour(taches: list[Path], sortie: Path, r: ReglagesRft, exclusion=None, base_hf: str = "A_RENSEIGNER",
         appeler: Callable[..., Reponse] = completer, afficher: Callable[[str], None] = print,
         **juges) -> dict[str, Any]:
    """Enchaîne essais, filtre et export. `juges` : juger_un_appel / juger_projet (tests)."""
    sortie = Path(sortie)
    registre = sortie / "registre.csv"
    lignes = lire_registre(registre)
    completes = {tid for tid in {l["tache_id"] for l in lignes}
                 if len({l["essai"] for l in lignes if l["tache_id"] == tid}) >= r.n_essais}
    bilan: dict[str, Any] = {"taches": len(taches), "reprises": 0, "essais": 0, "durees_s": []}
    debut = time.monotonic()
    from usine.taches import lire_tache
    for dossier in taches:
        tid = lire_tache(dossier)["id"]
        if tid in completes:
            bilan["reprises"] += 1
            continue
        nouveaux = []
        for n in range(r.n_essais):
            e = essayer(dossier, n, r, sortie / "sessions", appeler, **juges)
            nouveaux.append(_ligne(e))
            bilan["essais"] += 1
            bilan["durees_s"].append(e.duree_s)
            afficher(f"{tid:50s} essai {n}  {'OK ' if e.ok else 'NON'} {e.etape:12s} {e.duree_s:6.1f} s")
        lignes = [l for l in lignes if l["tache_id"] != tid] + nouveaux
        ecrire_registre(registre, lignes)            # atomique, après chaque tâche
    retenus, a_refaire = filtre.retenir(lignes)
    retenus, acquises = filtre.appliquer_difficulte(lignes, retenus, r.n_essais, r.mini_reussites, r.maxi_reussites)
    _ecrire_atomique(sortie / "acquises.txt", "".join(f"{t}\n" for t in sorted(acquises)))
    tampon = io.StringIO()
    w = csv.DictWriter(tampon, fieldnames=COLONNES, lineterminator="\n")
    w.writeheader()
    w.writerows({k: l[k] for k in COLONNES} for l in retenus)
    _ecrire_atomique(sortie / "retenus.csv", tampon.getvalue())
    _ecrire_atomique(sortie / "a_refaire.txt", "".join(f"{t}\n" for t in a_refaire))
    bilan_export = export.exporter(retenus, sortie / "sessions", sortie / "export", exclusion, base_hf)
    bilan.update({"retenus": len(retenus), "a_refaire": len(a_refaire), "acquises": len(acquises), "export": bilan_export,
                  "duree_s": round(time.monotonic() - debut, 1)})
    _ecrire_atomique(sortie / "bilan.json", json.dumps({k: v for k, v in bilan.items() if k != "durees_s"},
                                                        ensure_ascii=False, indent=2) + "\n")
    return bilan
