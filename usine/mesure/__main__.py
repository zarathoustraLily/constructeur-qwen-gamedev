"""CLI de la mesure.

  python -m usine.mesure executer   [--configurations ...] [--competences ...] [--limite N] [--tour t0]
  python -m usine.mesure juger-reponses <réponses.jsonl>        (référence frontière collectée en ligne)
  python -m usine.mesure rapport <résultats.jsonl ...> [--tour t0] [--gamedevbench final_results.json]
  python -m usine.mesure regression <ancien.jsonl> <nouveau.jsonl> [--configuration lora_rag]
  python -m usine.mesure simuler [--dossier D]                  (preuve cloud : résultats simulés)
  python -m usine.mesure gamedevbench preparer|lancer|score
"""

from __future__ import annotations

import argparse
import statistics
import sys
from pathlib import Path

from usine import config as cfg
from usine.mesure import executer as ex
from usine.mesure import gamedevbench as gdb
from usine.mesure import rapport, simulation


def _dossier_mesure(config: dict) -> Path:
    return cfg.dossier_donnees(config) / "mesure"


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="python -m usine.mesure")
    sous = p.add_subparsers(dest="cmd", required=True)

    e = sous.add_parser("executer", help="mesurer les configurations sur les jeux gelés")
    e.add_argument("--geles", type=Path, default=None)
    e.add_argument("--sortie", type=Path, default=None)
    e.add_argument("--tour", default="t0")
    e.add_argument("--configurations", nargs="*", default=list(ex.CONFIGURATIONS))
    e.add_argument("--competences", nargs="*", default=None)
    e.add_argument("--limite", type=int, default=None, help="tâches par compétence")
    e.add_argument("--index", type=Path, default=None, help="index du RAG (défaut : donnees/rag)")
    e.add_argument("--sans-agentiques", action="store_true", help="ne mesurer que les compétences en un appel")

    j = sous.add_parser("juger-reponses", help="juger des réponses collectées (référence frontière)")
    j.add_argument("reponses", type=Path)
    j.add_argument("--geles", type=Path, default=None)
    j.add_argument("--sortie", type=Path, default=None)

    r = sous.add_parser("rapport", help="rapport_mesure.md et .csv")
    r.add_argument("resultats", type=Path, nargs="+")
    r.add_argument("--tour", default=None)
    r.add_argument("--dossier", type=Path, default=None)
    r.add_argument("--gamedevbench", type=Path, default=None, help="final_results.json du runner GameDevBench")

    g = sous.add_parser("regression", help="non-régression entre deux tours")
    g.add_argument("ancien", type=Path)
    g.add_argument("nouveau", type=Path)
    g.add_argument("--configuration", default="lora_rag")

    s = sous.add_parser("simuler", help="rapport à partir de résultats simulés (preuve cloud)")
    s.add_argument("--dossier", type=Path, default=None)
    s.add_argument("--graine", type=int, default=1)

    b = sous.add_parser("gamedevbench", help="adaptateur GameDevBench (Godot 4.4.1)")
    b.add_argument("action", choices=("preparer", "lancer", "score"))
    b.add_argument("--depot", type=Path, default=None)
    b.add_argument("--ids", type=Path, default=None, help="sous-ensemble : un id task_NNNN par ligne")
    b.add_argument("--resultats", type=Path, default=None, help="final_results.json (action score)")

    a = p.parse_args(argv)
    try:
        return _commande(a)
    except ValueError as exc:
        print(f"Erreur : {exc}")
        return 2


def _commande(a: argparse.Namespace) -> int:
    config = cfg.charger_config()
    mesure = _dossier_mesure(config)

    if a.cmd == "executer":
        r_ = ex.reglages_depuis_config(config)
        r_.tour, r_.index = a.tour, a.index
        sortie = a.sortie or mesure / f"resultats_{a.tour}.jsonl"
        bilan = ex.executer(a.geles or cfg.dossier_donnees(config) / "geles", sortie, r_, a.configurations,
                            a.competences, a.limite, agentiques=not a.sans_agentiques)
        d = bilan["durees_appel_s"]
        print(f"{bilan['faites']} essais faits, {bilan['reprises']} déjà présents (reprise) ; résultats : {sortie}")
        if d:
            print(f"Durée d'un appel (ou d'une session agentique) : médiane {statistics.median(d):.1f} s, "
                  f"moyenne {statistics.fmean(d):.1f} s, max {max(d):.1f} s ({len(d)} essais)")
        for comp, n in bilan["non_mesurees"].items():
            print(f"Non mesurées : {comp} ({n} tâches, agentiques exclues)")
        return 0

    if a.cmd == "juger-reponses":
        sortie = a.sortie or mesure / "resultats_frontiere.jsonl"
        n = ex.juger_reponses(a.reponses, a.geles or cfg.dossier_donnees(config) / "geles", sortie)
        print(f"{n} réponses jugées ; résultats : {sortie}")
        return 0

    if a.cmd == "rapport":
        lignes = ex.lire_resultats(a.resultats)
        bloc = None
        if a.gamedevbench:
            sc, info = gdb.score(a.gamedevbench)
            depot = gdb.reglages(config)["depot"]
            bloc = gdb.lignes_rapport(sc, info, gdb.classement(depot) if depot else [])
        md, fichier_csv = rapport.ecrire(lignes, a.dossier or mesure, a.tour, gamedevbench=bloc)
        print(md.read_text(encoding="utf-8"))
        print(f"Écrit : {md} et {fichier_csv}")
        return 0

    if a.cmd == "regression":
        texte, ok = rapport.texte_regression(ex.lire_resultats([a.ancien]), ex.lire_resultats([a.nouveau]),
                                             a.configuration)
        print(texte)
        return 0 if ok else 1

    if a.cmd == "simuler":
        dossier = a.dossier or mesure / "simulation"
        dossier.mkdir(parents=True, exist_ok=True)
        lignes = simulation.simuler(graine=a.graine)
        fichier = dossier / "resultats_simules.jsonl"
        fichier.unlink(missing_ok=True)
        for l in lignes:
            ex.ajouter_ligne(fichier, l)
        md, fichier_csv = rapport.ecrire(ex.lire_resultats([fichier]), dossier, "t0",
                                         titre="Rapport de mesure (résultats simulés)",
                                         notes=["Résultats SIMULÉS (usine/mesure/simulation.py) : aucun modèle n'a tourné."])
        print(md.read_text(encoding="utf-8"))
        print(f"Écrit : {md} et {fichier_csv}")
        return 0

    if a.cmd == "gamedevbench":
        r_ = gdb.reglages(config)
        if a.depot:
            r_["depot"] = a.depot
        if a.action == "score":
            if not a.resultats:
                print("--resultats <final_results.json> attendu")
                return 2
            sc, info = gdb.score(a.resultats)
            print("\n".join(gdb.lignes_rapport(sc, info, gdb.classement(r_["depot"]) if r_["depot"] else [])))
            return 0
        if not r_["depot"]:
            print("[gamedevbench].depot à renseigner dans config.toml (ou --depot)")
            return 2
        problemes = gdb.verifier_depot(r_["depot"])
        if problemes:
            print("\n".join(problemes))
            return 1
        liste = mesure / "gamedevbench" / "taches.yaml"
        if a.action == "preparer":
            if not r_["godot"]:
                print("[godot].console_gamedevbench à renseigner (Godot 4.4.1)")
                return 2
            version = gdb.version_godot(r_["godot"])
            if not version.startswith(gdb.VERSION_GODOT):
                print(f"Godot {gdb.VERSION_GODOT} attendu, trouvé : {version or 'rien'}")
                return 1
            n = gdb.decompresser(r_["depot"])
            ids = gdb.lire_liste(r_["depot"] / "tasks.yaml")
            if a.ids:
                voulus = {l.strip() for l in a.ids.read_text(encoding="utf-8").splitlines() if l.strip()}
                ids = [i for i in ids if i in voulus]
            gdb.ecrire_liste(liste, ids)
            cmd, env = gdb.commande(r_, liste)
            print(f"Godot : {version}\n{n} archives décompressées ; {len(ids)} tâches dans {liste}")
            print("Commande (dans le dépôt) : " + " ".join(cmd))
            print("Environnement : " + " ".join(f"{k}={v}" for k, v in env.items()))
            return 0
        if not liste.is_file():
            print("Lancer d'abord : python -m usine.mesure gamedevbench preparer")
            return 2
        return gdb.lancer(r_, liste)
    return 2


if __name__ == "__main__":
    sys.exit(main())
