"""CLI de la base d'un cours : « bâtiments procéduraux » par défaut, ou un cours de jeu (--cours kart, roguelike).

    python -m usine.cours.base generer [--cours kart] [--villes parisien …] [--etapes 1 2 …] [--travailleurs 2] [--refaire]
    python -m usine.cours.base assembler [--cours kart]
    python -m usine.cours.base tout [--cours kart] [--travailleurs 2]

Chemins (sinon lus dans config.toml) : --docs (godot-docs), --source-godot (godot à l'étiquette 4.7.2-stable),
--vocab (GGUF de Qwen 3.8 : le modèle ou son vocabulaire seul), --opencode-session (session OpenCode capturée par
le proxy), --opencode-godot (Godot console chez laurent, chemin Windows), --opencode-dossier (dossier Windows des
projets du cours chez laurent).
"""

from __future__ import annotations

import argparse
import sys


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(prog="python -m usine.cours.base")
    sous = parser.add_subparsers(dest="commande", required=True)
    for nom, aide in (("generer", "exemples de création et sessions de débogage, étape par étape"),
                      ("assembler", "contrôles, statistiques, fichiers d'entraînement"),
                      ("tout", "generer, puis assembler")):
        p = sous.add_parser(nom, help=aide)
        p.add_argument("--cours", default=None, help="batiments_proceduraux (défaut), kart, roguelike")
        p.add_argument("--docs")
        p.add_argument("--source-godot")
        p.add_argument("--vocab")
        p.add_argument("--opencode-session")
        p.add_argument("--opencode-godot")
        p.add_argument("--opencode-dossier")
        if nom != "assembler":
            p.add_argument("--villes", nargs="*")
            p.add_argument("--etapes", nargs="*", type=int)
            p.add_argument("--travailleurs", type=int, default=1)
            p.add_argument("--refaire", action="store_true", help="refaire les étapes déjà générées")
    args = parser.parse_args(argv)
    reglages = {"cours": args.cours, "docs": args.docs, "source_godot": args.source_godot, "vocab": args.vocab,
                "session_opencode": args.opencode_session,
                "godot_windows": args.opencode_godot, "dossier_windows": args.opencode_dossier}

    from usine.cours.base import chemins
    chemins.configurer(**reglages)
    if args.commande in ("generer", "tout"):
        from usine.cours.base.generer import generer
        echecs = generer(args.villes, args.etapes, args.travailleurs, reglages, args.refaire,
                         journal=lambda t: print(t, flush=True))
        if echecs:
            print(f"{echecs} étape(s) en échec : voir ci-dessus")
            return 1
    if args.commande in ("assembler", "tout"):
        from usine.cours.base.assembler import assembler
        controles = assembler(journal=lambda t: print(t, flush=True))
        return 0 if not controles["problemes"] else 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
