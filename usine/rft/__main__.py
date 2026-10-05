"""CLI de la boucle RFT (session 5).

  python -m usine.rft tour --sortie donnees/rft/t1 [--competences ...] [--limite N] [--n-essais 4]
                           [--harnais agent|opencode] [--depuis donnees/rft/t0/a_refaire.txt]
  python -m usine.rft exporter --sortie donnees/rft/t1          (refait l'export d'un tour)
  python -m usine.rft gguf --adaptateur <dossier> --sortie <fichier.gguf>
  python -m usine.rft lanceur --sortie lancer_qwen_lora.bat --lora a.gguf [--lora b.gguf ...]
  python -m usine.rft preuve                                    (preuve cloud : faux serveur juste à 60 %)
"""

from __future__ import annotations

import argparse
import statistics
import sys
from pathlib import Path

from usine import config as cfg


def _base_hf(config: dict) -> str:
    v = config.get("entrainement", {}).get("base_hf")
    return v if v and v != cfg.A_RENSEIGNER else cfg.A_RENSEIGNER


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="python -m usine.rft")
    sous = p.add_subparsers(dest="cmd", required=True)
    t = sous.add_parser("tour", help="essais → filtre → export (reprise après coupure)")
    t.add_argument("--taches", type=Path, default=None, help="défaut : donnees/taches")
    t.add_argument("--sortie", type=Path, required=True)
    t.add_argument("--competences", nargs="*", default=None)
    t.add_argument("--limite", type=int, default=None, help="tâches par compétence")
    t.add_argument("--n-essais", type=int, default=None)
    t.add_argument("--harnais", choices=("agent", "opencode"), default=None)
    t.add_argument("--depuis", type=Path, default=None, help="a_refaire.txt du tour précédent")
    e = sous.add_parser("exporter", help="refaire l'export d'un tour")
    e.add_argument("--sortie", type=Path, required=True)
    g = sous.add_parser("gguf", help="convertir l'adaptateur en GGUF (convert_lora_to_gguf.py)")
    g.add_argument("--adaptateur", type=Path, required=True)
    g.add_argument("--sortie", type=Path, required=True)
    g.add_argument("--outtype", default="f16")
    lc = sous.add_parser("lanceur", help="écrire le .bat llama-server multi-LoRA")
    lc.add_argument("--sortie", type=Path, required=True)
    lc.add_argument("--lora", type=Path, action="append", default=[])
    lc.add_argument("--port", type=int, default=8080)
    lc.add_argument("--init-sans-appliquer", action="store_true")
    pr = sous.add_parser("preuve", help="mini-tour contre un faux serveur juste à 60 %")
    pr.add_argument("--dossier", type=Path, default=None)
    a = p.parse_args(argv)
    config = cfg.charger_config()

    if a.cmd == "preuve":
        from usine.rft.preuve import preuve
        return preuve(a.dossier)

    if a.cmd == "tour":
        from usine.portillon.exclusion import Exclusion
        from usine.rft.essais import reglages_depuis_config
        from usine.rft.tour import selectionner, tour
        r = reglages_depuis_config(config)
        if a.n_essais:
            r.n_essais = a.n_essais
        if a.harnais:
            r.harnais = a.harnais
        exclusion = Exclusion.charger()
        taches = selectionner(a.taches or cfg.dossier_donnees(config) / "taches", a.competences, a.depuis, a.limite,
                              exclusion)
        print(f"{len(taches)} tâches × {r.n_essais} essais ; harnais agentique : {r.harnais}")
        bilan = tour(taches, a.sortie, r, exclusion, _base_hf(config))
        d = bilan["durees_s"]
        print(f"{bilan['essais']} essais faits, {bilan['reprises']} tâches déjà faites (reprise) ; "
              f"retenues {bilan['retenus']}, à refaire {bilan['a_refaire']} ; export {bilan['export']}")
        if d:
            print(f"Temps par essai : médiane {statistics.median(d):.1f} s, moyenne {statistics.fmean(d):.1f} s, "
                  f"max {max(d):.1f} s ({len(d)} essais) ; durée du tour {bilan['duree_s']} s")
        return 0

    if a.cmd == "exporter":
        from usine.portillon.exclusion import Exclusion
        from usine.rft import export, filtre
        from usine.rft.tour import lire_registre
        retenus, _ = filtre.retenir(lire_registre(a.sortie / "registre.csv"))
        print(export.exporter(retenus, a.sortie / "sessions", a.sortie / "export", Exclusion.charger(),
                              _base_hf(config)))
        return 0

    if a.cmd == "gguf":
        from usine.rft import gguf
        e_ = config.get("entrainement", {})
        conv, base = e_.get("convertisseur_lora"), e_.get("base_hf")
        if not conv or conv == cfg.A_RENSEIGNER or not base or base == cfg.A_RENSEIGNER:
            print("[entrainement].convertisseur_lora et base_hf à renseigner dans config.toml")
            return 2
        res = gguf.convertir(Path(conv), a.adaptateur, Path(base), a.sortie, a.outtype)
        print(res.sortie[-2000:])
        print(f"code {res.code}, {res.duree_s:.0f} s ; GGUF : {a.sortie}")
        return 0 if res.code == 0 and a.sortie.is_file() else 1

    if a.cmd == "lanceur":
        from usine.rft import gguf
        r_ = config.get("rft", {})
        serveur, modele = r_.get("serveur_llama"), r_.get("modele_gguf")
        if not serveur or serveur == cfg.A_RENSEIGNER or not modele or modele == cfg.A_RENSEIGNER:
            print("[rft].serveur_llama et modele_gguf à renseigner dans config.toml")
            return 2
        chemin = gguf.ecrire_lanceur(a.sortie, Path(serveur), Path(modele), a.lora, port=a.port,
                                     init_sans_appliquer=a.init_sans_appliquer)
        print(chemin.read_text(encoding="utf-8"))
        return 0
    return 2


if __name__ == "__main__":
    sys.exit(main())
