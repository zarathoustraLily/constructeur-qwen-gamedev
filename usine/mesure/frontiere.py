"""Référence frontière (optionnelle) : interroge une API externe. DÉSACTIVÉE PAR DÉFAUT.

Seule exception à la règle 9 (pas d'appel externe). Le script ne tourne que si les deux
conditions sont réunies :
  - `[frontiere] active = true` dans config.toml ;
  - l'option `--appel-externe` sur la ligne de commande.
Aucun autre module de l'usine ne l'importe ni ne le lance (vérifié par tests/test_mesure.py).

À lancer depuis le mini-PC en ligne, avec une clé fournie par l'utilisateur dans une variable
d'environnement (`[frontiere] cle_env`, par défaut FRONTIERE_CLE). Le script ne fait que
collecter les réponses dans un JSONL ; elles sont jugées ensuite, hors-ligne, sur la machine :
    python -m usine.mesure juger-reponses <réponses.jsonl>

Compétences en un appel seulement, en deux variantes, avec le même prompt que Qwen :
  frontiere      sans adaptation, sans RAG ;
  frontiere_rag  sans adaptation, avec les mêmes extraits du RAG (même index, même requête).
La règle de victoire compare LoRA + RAG à frontiere_rag.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any, Callable

from usine import config as cfg
from usine.mesure import reponses
from usine.mesure.client import ErreurAppel, Reglages, Reponse, completer
from usine.mesure.executer import ReglagesMesure, ajouter_ligne, documentation, taches_gelees

VARIANTES = {"frontiere": False, "frontiere_rag": True}


def reglages(config: dict[str, Any]) -> Reglages:
    f = config.get("frontiere", {})
    cle_env = f.get("cle_env", "FRONTIERE_CLE")
    cle = os.environ.get(cle_env)
    if not cle:
        raise SystemExit(f"clé absente : définir la variable d'environnement {cle_env}")
    for champ in ("url", "modele"):
        if not f.get(champ) or f[champ] == cfg.A_RENSEIGNER:
            raise SystemExit(f"[frontiere].{champ} à renseigner dans config.toml")
    return Reglages(url=f["url"], modele=f["modele"], cle=cle, protocole=f.get("protocole", "openai"),
                    max_jetons=int(f.get("max_jetons", config.get("mesure", {}).get("max_jetons", 4096))),
                    temperature=float(f.get("temperature", 0.0)), delai_s=float(f.get("delai_s", 600)))


def collecter(geles: Path, sortie: Path, client: Reglages, competences: list[str] | None = None,
              limite: int | None = None, n_docs: int = 5, index: Path | None = None,
              appeler: Callable[..., Reponse] = completer,
              doc: Callable[[str, ReglagesMesure], str] = documentation,
              afficher: Callable[[str], None] = print) -> int:
    """Collecte les réponses (sans les juger). Reprend après coupure : rien n'est redemandé."""
    from usine.taches import lire_tache
    sortie = Path(sortie)
    deja = set()
    if sortie.is_file():
        for brut in sortie.read_text(encoding="utf-8").splitlines():
            try:
                l = json.loads(brut)
            except json.JSONDecodeError:
                continue
            deja.add((l["configuration"], l["tache_id"], l.get("empreinte")))
    voulues = [c for c in (competences or reponses.COMPETENCES_UN_APPEL) if c in reponses.COMPETENCES_UN_APPEL]
    r_doc = ReglagesMesure(n_docs=n_docs, index=index)
    vus: dict[str, int] = {}
    n = 0
    for dossier in taches_gelees(geles, voulues):
        tache = lire_tache(dossier)
        comp = tache["competence"]
        vus[comp] = vus.get(comp, 0) + 1
        if limite and vus[comp] > limite:
            continue
        docs = None
        for conf, avec_rag in VARIANTES.items():
            if (conf, tache["id"], tache["empreinte"]) in deja:
                continue
            if avec_rag and docs is None:
                docs = doc(tache["consigne"], r_doc)
            msgs = reponses.messages(dossier / "depart", tache["consigne"], comp, docs if avec_rag else None)
            schema = reponses.SCHEMAS[comp] if client.protocole == "openai" else None
            try:
                rep = appeler(client, msgs, schema, None)
                ligne = {"contenu_ok": True, "reponse": rep.contenu, "duree_appel_s": rep.duree_s,
                         "jetons_entree": rep.jetons_entree, "jetons_sortie": rep.jetons_sortie, "fin": rep.fin}
            except ErreurAppel as exc:
                ligne = {"contenu_ok": False, "reponse": "", "erreur": str(exc)[:300], "duree_appel_s": 0.0}
            ligne.update({"tour": "frontiere", "configuration": conf, "competence": comp, "tache_id": tache["id"],
                          "empreinte": tache["empreinte"], "modele": client.modele})
            ajouter_ligne(sortie, ligne)
            n += 1
            afficher(f"{conf:13s} {tache['id']:50s} {'reçu' if ligne['contenu_ok'] else 'ÉCHEC : ' + ligne['erreur']}")
    return n


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="python -m usine.mesure.frontiere",
                                description="Référence frontière (appel externe, désactivée par défaut).")
    p.add_argument("--appel-externe", action="store_true", help="confirme l'appel à l'API externe")
    p.add_argument("--geles", type=Path, default=None, help="jeux gelés (défaut : donnees/geles)")
    p.add_argument("--sortie", type=Path, default=None)
    p.add_argument("--competences", nargs="*", default=None)
    p.add_argument("--limite", type=int, default=None, help="tâches par compétence")
    a = p.parse_args(argv)
    config = cfg.charger_config()
    if not config.get("frontiere", {}).get("active", False):
        print("Référence frontière désactivée : [frontiere] active = false dans config.toml.")
        return 2
    if not a.appel_externe:
        print("Appel externe non confirmé : ajouter --appel-externe.")
        return 2
    geles = a.geles or cfg.dossier_donnees(config) / "geles"
    sortie = a.sortie or cfg.dossier_donnees(config) / "mesure" / "frontiere_reponses.jsonl"
    n = collecter(geles, sortie, reglages(config), a.competences, a.limite,
                  int(config.get("mesure", {}).get("n_docs", 5)))
    print(f"{n} réponses collectées dans {sortie}")
    print(f"Ensuite, sur la machine : python -m usine.mesure juger-reponses {sortie}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
