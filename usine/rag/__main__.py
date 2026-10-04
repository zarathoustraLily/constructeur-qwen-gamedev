"""CLI du RAG de documentation Godot (hors-ligne).

    python -m usine.rag construire [--docs <copie de godot-docs>] [--sortie <index.sqlite>]
    python -m usine.rag chercher "CharacterBody2D" [-n 5] [--json]
    python -m usine.rag verifier
    python -m usine.rag vecteurs [--url http://127.0.0.1:8080/v1] [--lot 32]   (option sqlite-vec)

`construire` lit `[chemins].docs_godot` de config.toml si --docs est absent.
`verifier` relit chaque fragment de l'index contre les jeux gelés : code 0 si aucune
solution gelée n'y entre et que l'index a été construit avec le manifeste actuel.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from usine import config as cfg


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(prog="python -m usine.rag")
    sous = parser.add_subparsers(dest="commande", required=True)
    p = sous.add_parser("construire", help="godot-docs (rst) → index SQLite FTS5")
    p.add_argument("--docs", type=Path)
    p.add_argument("--sortie", type=Path)
    p = sous.add_parser("chercher", help="search_docs")
    p.add_argument("requete")
    p.add_argument("-n", type=int, default=5)
    p.add_argument("--json", action="store_true")
    p.add_argument("--index", type=Path)
    p = sous.add_parser("verifier", help="aucune solution gelée dans l'index")
    p.add_argument("--index", type=Path)
    p = sous.add_parser("vecteurs", help="plongements sqlite-vec par le llama-server local (option)")
    p.add_argument("--url", default=None)
    p.add_argument("--lot", type=int, default=32)
    p.add_argument("--index", type=Path)
    args = parser.parse_args(argv)

    from usine.rag import index as rag

    if args.commande == "construire":
        docs = args.docs or rag.chemin_docs()
        if docs is None:
            print("Renseigner [chemins].docs_godot dans config.toml ou passer --docs.", file=sys.stderr)
            return 2
        r = rag.construire(docs, args.sortie)
        print(f"index : {r['index']}")
        print(f"pages : {r['pages']}   fragments : {r['fragments']}   durée : {r['duree_s']} s")
        print(f"gel : {'manifeste ' + r['manifeste'][:16] + '…' if r['manifeste'] else 'aucun manifeste (rien à exclure)'}")
        print(f"fragments exclus (solution gelée) : {len(r['exclus'])}")
        for source, titre, tache in r["exclus"]:
            print(f"  {source} « {titre} » ← {tache}")
        return 0
    if args.commande == "chercher":
        res = rag.IndexDocs(args.index, plonger=rag.plongeur_configure()).chercher(args.requete, args.n)
        if args.json:
            print(json.dumps(res, ensure_ascii=False, indent=1))
        else:
            for i, r in enumerate(res, 1):
                print(f"{i}. [{r['trouve_par']}] {r['titre']}  ({r['source']})")
        return 0 if res else 1
    if args.commande == "verifier":
        from usine.portillon.exclusion import Exclusion
        idx = rag.IndexDocs(args.index)
        r = idx.verifier_exclusion(Exclusion.charger())
        print(f"index : {idx.base} ({r['fragments']} fragments, révision godot-docs {idx.meta.get('revision_docs')})")
        print(f"tâches gelées : {r['taches_gelees']}   exclus à la construction : {r['exclus_a_la_construction']}")
        print(f"manifeste du gel identique à celui de la construction : {'oui' if r['manifeste_a_jour'] else 'NON (reconstruire)'}")
        print(f"fragments qui reprennent une solution gelée : {len(r['fuites'])}")
        for f in r["fuites"]:
            print(f"  {f['source']} « {f['titre']} » ← {f['tache_id']}")
        return 0 if not r["fuites"] and r["manifeste_a_jour"] else 1
    from usine.rag import vecteurs
    if not vecteurs.disponible():
        print("sqlite-vec absent : pip install sqlite-vec (option).", file=sys.stderr)
        return 2
    url = args.url or cfg.charger_config().get("llm", {}).get("url", "http://127.0.0.1:8080/v1")
    n = vecteurs.calculer(Path(args.index or rag.chemin_index()), vecteurs.plongeur_llama(url), args.lot)
    print(f"{n} fragments plongés ; activer [rag].vecteurs = true dans config.toml pour s'en servir.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
