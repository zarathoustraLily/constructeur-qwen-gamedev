"""CLI du vocabulaire.

    python -m usine.vocab construire [--json extension_api.json]
    python -m usine.vocab lookup CharacterBody2D [membre] [--genre signal] [--json] [--toutes-methodes]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from usine.vocab.construire import construire
from usine.vocab.requete import GENRES, ouvrir


def _signature(nom: str, args: list[dict]) -> str:
    return f"{nom}(" + ", ".join(f"{a['nom']}: {a['type']}" for a in args) + ")"


def _afficher(desc: dict, toutes_methodes: bool) -> None:
    classe = desc["classe"]
    print(f"{classe} (Godot {desc['version']})")
    print("Héritage : " + " → ".join(desc["heritage"]))

    def section(titre: str, elements: list[dict], fmt) -> None:
        print(f"\n{titre} ({len(elements)}) :")
        for e in elements:
            print(f"  [{e['origine']}] {fmt(e)}")

    section("Signaux", desc["signaux"], lambda s: _signature(s["nom"], s["arguments"]))
    section("Propriétés", desc["proprietes"], lambda p: f"{p['nom']}: {p['type']}")
    methodes = desc["methodes"] if toutes_methodes else [m for m in desc["methodes"] if m["origine"] == classe]
    titre = "Méthodes" if toutes_methodes else f"Méthodes propres (sur {len(desc['methodes'])} avec l'héritage ; --toutes-methodes)"
    section(titre, methodes, lambda m: _signature(m["nom"], m["arguments"]) + (f" -> {m['retour']}" if m["retour"] else ""))
    section("Énumérations", desc["enums"], lambda e: e["nom"] + " { " + ", ".join(v["nom"] for v in e["valeurs"]) + " }")
    section("Constantes", desc["constantes"], lambda c: f"{c['nom']} = {c['valeur']}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m usine.vocab", description="Vocabulaire Godot exact.")
    sous = parser.add_subparsers(dest="commande", required=True)
    p_c = sous.add_parser("construire", help="extension_api.json → SQLite")
    p_c.add_argument("--json", type=Path, help="extension_api.json existant (sinon : extrait par Godot)")
    p_l = sous.add_parser("lookup", help="décrire une classe ou vérifier un membre")
    p_l.add_argument("classe")
    p_l.add_argument("membre", nargs="?")
    p_l.add_argument("--genre", choices=sorted(GENRES))
    p_l.add_argument("--json", action="store_true", help="sortie JSON")
    p_l.add_argument("--toutes-methodes", action="store_true")
    args = parser.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")  # console Windows redirigée : éviter cp1252

    if args.commande == "construire":
        print(construire(args.json))
        return 0

    vocab = ouvrir()
    if not vocab.classe_existe(args.classe):
        print(f"classe inconnue : {args.classe}", file=sys.stderr)
        return 2
    if args.membre:
        origine = vocab.definie_dans(args.classe, args.membre, args.genre)
        resultat = {"classe": args.classe, "membre": args.membre, "genre": args.genre,
                    "existe": origine is not None, "origine": origine}
        if args.json:
            print(json.dumps(resultat, ensure_ascii=False))
        else:
            print(f"{args.classe}.{args.membre} : " + (f"existe (défini dans {origine})" if origine else "n'existe pas"))
        return 0 if origine else 1
    desc = vocab.decrire(args.classe)
    if args.json:
        print(json.dumps(desc, ensure_ascii=False, indent=1))
    else:
        _afficher(desc, args.toutes_methodes)
    return 0


if __name__ == "__main__":
    sys.exit(main())
