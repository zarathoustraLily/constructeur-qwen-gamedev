"""CLI des cours en étapes.

    python -m usine.cours fabriquer batiments_proceduraux [--villes parisien …] [--etapes 1 2 …] [--sortie <dossier>]
    python -m usine.cours juger batiments_proceduraux [--sortie <dossier>]
    python -m usine.cours verifier batiments_proceduraux [--villes …] [--etapes …] [--sans-rendu] [--travailleurs 2]

`fabriquer` écrit un projet Godot par étape (défaut : donnees/cours/<cours>/projets/). `juger` passe le juge des
règles sur les projets fabriqués. `verifier` lance en plus Godot sur chacun (import, analyse de chaque script,
test de l'étape, une image en Compatibilité) et écrit le bilan dans donnees/cours/<cours>/verification.json.
"""

from __future__ import annotations

import argparse
import json
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from usine.cours import dossier_cours, dossier_projets
from usine.cours.fabriquer import etapes_demandees, fabriquer_tout, lire_manifeste, nom_projet


def _projets(cours: str, sortie: Path, villes: list[str] | None, etapes: list[int] | None) -> list[Path]:
    manifeste = lire_manifeste(dossier_cours(cours))
    return [sortie / nom_projet(v, n) for v, n in etapes_demandees(manifeste, villes, etapes)]


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(prog="python -m usine.cours")
    sous = parser.add_subparsers(dest="commande", required=True)
    for nom, aide in (("fabriquer", "un projet Godot par étape, à partir des maîtres"),
                      ("juger", "juge des règles sur les projets fabriqués"),
                      ("verifier", "juge des règles, puis Godot sur chaque projet fabriqué")):
        p = sous.add_parser(nom, help=aide)
        p.add_argument("cours")
        p.add_argument("--villes", nargs="*")
        p.add_argument("--etapes", nargs="*", type=int)
        p.add_argument("--sortie", type=Path)
        if nom == "verifier":
            p.add_argument("--sans-rendu", action="store_true", help="pas d'image en Compatibilité")
            p.add_argument("--travailleurs", type=int, default=2)
    args = parser.parse_args(argv)
    sortie = args.sortie or dossier_projets(args.cours)

    if args.commande == "fabriquer":
        for rapport in fabriquer_tout(dossier_cours(args.cours), sortie, args.villes, args.etapes):
            etats: dict[str, int] = {}
            for entree in rapport["fichiers"]:
                etats[entree["etat"]] = etats.get(entree["etat"], 0) + 1
            print(f"{rapport['nom']} : {len(rapport['fichiers'])} fichiers {etats}")
        print(f"Projets dans {sortie}")
        return 0

    projets = _projets(args.cours, sortie, args.villes, args.etapes)
    absents = [p.name for p in projets if not (p / "project.godot").is_file()]
    if absents:
        print(f"Projets absents (lancer d'abord « fabriquer ») : {absents[:5]}")
        return 2
    if args.commande == "juger":
        from usine.regles import par_regle, verifier_regles
        total = 0
        for projet in projets:
            verdict = verifier_regles(projet)
            total += len(verdict.get("erreurs", []))
            print(f"{projet.name} : {len(verdict.get('erreurs', []))} écart(s) {par_regle(verdict)}")
        print(f"{len(projets)} projets, {total} écart(s)")
        return 0 if total == 0 else 1

    from usine.cours.verifier import verifier_projet
    images = sortie.parent / "images"

    def un(projet: Path) -> tuple[str, dict]:
        bilan = verifier_projet(projet, rendu=not args.sans_rendu, image=images / f"{projet.name}.png")
        print(f"{projet.name} : {'ok' if bilan['ok'] else 'ÉCHEC'} {bilan['regles'] or ''}", flush=True)
        return projet.name, bilan

    with ThreadPoolExecutor(max(1, args.travailleurs)) as pool:
        bilans = dict(pool.map(un, projets))
    fichier = sortie.parent / "verification.json"
    fichier.write_text(json.dumps(bilans, ensure_ascii=False, indent=1), encoding="utf-8")
    reussis = sum(1 for b in bilans.values() if b["ok"])
    print(f"{reussis}/{len(bilans)} projets vérifiés sans erreur ; bilan : {fichier}")
    return 0 if reussis == len(bilans) else 1


if __name__ == "__main__":
    raise SystemExit(main())
