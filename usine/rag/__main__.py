"""CLI du RAG de documentation Godot (hors-ligne).

    python -m usine.rag construire [--docs <godot-docs>] [--demos <godot-demo-projects>] [--sans-demos]
    python -m usine.rag chercher "CharacterBody2D" [-n 5] [--source tout|doc|exemples] [--json]
    python -m usine.rag verifier [--taches <dossier de tâches>] [--temoin <projet source>]
    python -m usine.rag vecteurs [--url http://127.0.0.1:8080/v1] [--lot 32]   (option sqlite-vec)
    python -m usine.rag banc [-n 5] [--rates 10]
    python -m usine.rag banc-docs [-n 5] [--par-groupe 1000] [--source tout|doc] [--rates 10]

`construire` lit `[chemins].docs_godot` et `[chemins].demos_godot` de config.toml si les options
sont absentes. Les démos sont d'abord vérifiées par Godot (import + compilation de chaque
script) : une fois par révision du dépôt, rapport dans donnees/rag/verification_demos.json.
`[rag].demos_exclues` retire des projets entiers (démo devenue source de tâches gelées).
`verifier` relit chaque fragment de l'index contre les jeux gelés : code 0 si aucune
solution gelée n'y entre et que l'index a été construit avec le manifeste actuel.
Avec --taches, le contrôle porte sur toutes les tâches du dossier (par exemple
donnees/candidats, dont le gel est tiré) au lieu du seul manifeste du gel. --temoin passe
les scripts d'un projet source par le même détecteur (témoin positif : il doit y reconnaître
des réponses).
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
    p.add_argument("--demos", type=Path)
    p.add_argument("--sans-demos", action="store_true")
    p.add_argument("--travailleurs", type=int, default=2)
    p.add_argument("--sortie", type=Path)
    p.add_argument("--sans-nos-sources", action="store_true", help="sans nos cours ni nos fiches de plugins")
    p = sous.add_parser("chercher", help="search_docs")
    p.add_argument("requete")
    p.add_argument("-n", type=int, default=5)
    p.add_argument("--source", default="tout", choices=["tout", "doc", "exemples"])
    p.add_argument("--json", action="store_true")
    p.add_argument("--index", type=Path)
    p = sous.add_parser("verifier", help="aucune solution gelée dans l'index")
    p.add_argument("--index", type=Path)
    p.add_argument("--taches", type=Path, help="contrôler contre toutes les tâches de ce dossier")
    p.add_argument("--temoin", type=Path, help="projet source dont les scripts doivent être reconnus")
    p = sous.add_parser("banc", help="demandes en français tirées des notes des cours (banc.py)")
    p.add_argument("-n", type=int, default=5)
    p.add_argument("--index", type=Path)
    p.add_argument("--rates", type=int, default=0, help="afficher autant de demandes ratées")
    p = sous.add_parser("banc-docs", help="questions de godot-docs-dataset : couverture et recherche (banc_docs.py)")
    p.add_argument("-n", type=int, default=5)
    p.add_argument("--par-groupe", type=int, default=1000, help="questions par groupe (0 : toutes)")
    p.add_argument("--source", default="tout", choices=["tout", "doc"])
    p.add_argument("--index", type=Path)
    p.add_argument("--rates", type=int, default=0, help="afficher autant de questions ratées par groupe")
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
        from usine.rag.exemples import chemin_demos, verifier_demos
        demos = None if args.sans_demos else (args.demos or chemin_demos())
        verification = None
        if demos is not None:
            sortie = Path(args.sortie or rag.chemin_index())
            print(f"Vérification des démos de {demos} (Godot, une fois par révision)…")
            verification = verifier_demos(demos, sortie.parent / "verification_demos.json", args.travailleurs)
        exclues = cfg.charger_config().get("rag", {}).get("demos_exclues", [])
        r = rag.construire(docs, args.sortie, demos=demos, verification=verification, demos_exclues=exclues,
                           nos_sources=not args.sans_nos_sources)
        print(f"index : {r['index']}")
        print(f"pages : {r['pages']}   fragments : {r['fragments']}   durée : {r['duree_s']} s")
        if r["demos"]:
            d = r["demos"]
            print(f"démos : {d['projets']} projets, {d['scripts_verifies']} scripts qui compilent indexés, "
                  f"{d['scripts_ecartes']} écartés ; projets retirés : {exclues or 'aucun'}")
        else:
            print("démos : aucune (exemples vérifiés absents)")
        for nom, c in r["nos_sources"].items():
            print(f"nos sources, {nom} : {c}")
        print(f"gel : {'manifeste ' + r['manifeste'][:16] + '…' if r['manifeste'] else 'aucun manifeste (rien à exclure)'}")
        print(f"fragments exclus (solution gelée) : {len(r['exclus'])}")
        for source, titre, tache in r["exclus"]:
            print(f"  {source} « {titre} » ← {tache}")
        return 0
    if args.commande == "banc":
        from usine.rag.banc import mesurer
        r = mesurer(args.n, args.index)
        print(f"{r['points']} demandes ; dans les {r['n']} premiers résultats : page de référence attendue "
              f"{r['reference']} ({r['taux_reference']:.1%}), fragment utile {r['utiles']} ({r['taux_utiles']:.1%})")
        for cours, s in r["par_cours"].items():
            print(f"  {cours} : {s}")
        for x in r["rates"][:args.rates]:
            print(f"  raté : {x['demande']} {x['attendues']} → {x['obtenus'][:3]}")
        return 0
    if args.commande == "banc-docs":
        from usine.rag.banc_docs import mesurer as mesurer_docs
        r = mesurer_docs(args.n, args.par_groupe, args.source, args.index)
        print(f"{r['lignes']} couples page#ancre (révision {r['revision'][:12]}) ; source {r['source']}, "
              f"{r['n']} premiers résultats")
        for g, c in r["couverture"].items():
            s = r["recherche"][g]
            print(f"  {g} : couverture pages {c['pages']}/{c['total']}, ancres {c['ancres']}/{c['total']} ; "
                  f"recherche page {s['page']}/{s['total']}, précis {s['precis']}/{s['total']}")
            for x in r["absentes"].get(g, [])[:args.rates]:
                print(f"    absente : {x}")
            for x in r["rates"].get(g, [])[:args.rates]:
                print(f"    ratée : {x['question']} → {x['attendu']} ; obtenus {x['obtenus'][:3]}")
        return 0
    if args.commande == "chercher":
        res = rag.IndexDocs(args.index, plonger=rag.plongeur_configure()).chercher(args.requete, args.n, args.source)
        if args.json:
            print(json.dumps(res, ensure_ascii=False, indent=1))
        else:
            for i, r in enumerate(res, 1):
                print(f"{i}. [{r['trouve_par']}] {r['titre']}  ({r['source']})")
        return 0 if res else 1
    if args.commande == "verifier":
        from usine.portillon.exclusion import Exclusion
        idx = rag.IndexDocs(args.index)
        exclusion = Exclusion.depuis_taches(args.taches) if args.taches else Exclusion.charger()
        r = idx.verifier_exclusion(exclusion)
        print(f"index : {idx.base} ({r['fragments']} fragments, révision godot-docs {idx.meta.get('revision_docs')})")
        if args.taches:
            print(f"tâches contrôlées : {r['taches_gelees']} (toutes celles de {args.taches})")
        else:
            print(f"tâches gelées : {r['taches_gelees']}   exclus à la construction : {r['exclus_a_la_construction']}")
            print(f"manifeste du gel identique à celui de la construction : "
                  f"{'oui' if r['manifeste_a_jour'] else 'NON (reconstruire)'}")
        print(f"fragments qui reprennent une tâche : {len(r['fuites'])}")
        for f in r["fuites"]:
            print(f"  {f['source']} « {f['titre']} » ← {f['tache_id']}")
        temoin_ok = True
        if args.temoin:
            from usine.rag.exemples import fragments_script
            fr = [f for s in sorted(args.temoin.rglob("*.gd")) if "addons" not in s.relative_to(args.temoin).parts
                  and ".godot" not in s.relative_to(args.temoin).parts
                  for f in fragments_script(args.temoin.name, "res://" + s.relative_to(args.temoin).as_posix(),
                                            s.read_text(encoding="utf-8"))]
            reconnus = sum(1 for f in fr if exclusion.texte_exclu(f.texte))
            temoin_ok = reconnus > 0
            print(f"témoin positif : {reconnus}/{len(fr)} fragments des scripts de {args.temoin} reconnus comme réponses")
        return 0 if not r["fuites"] and (args.taches or r["manifeste_a_jour"]) and temoin_ok else 1
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
