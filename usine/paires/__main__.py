"""CLI des paires courtes.

    python -m usine.paires camera [--niveaux N] [--graine G] [--paires P]
    python -m usine.paires editeur [--niveaux N] [--graine G] [--paires P]
    python -m usine.paires timing [--niveaux N] [--graine G] [--paires P]
    python -m usine.paires compilation [--cours kart] [--par-etape N] [--graine G] [--etapes 1,2]
    python -m usine.paires shader [--cours kart] [--par-etape N] [--graine G] [--etapes 1,2]
    python -m usine.paires execution [--cours kart] [--par-etape N] [--graine G] [--etapes 1,2]
    python -m usine.paires creation [--cours kart] [--par-etape N] [--graine G] [--etapes 1,2]
    python -m usine.paires lecture
    python -m usine.paires rag
    python -m usine.paires points [--cours kart] [--etapes 1,2]
    python -m usine.paires maillage [--par-etape N] [--graine G] [--etapes 1,2]
    python -m usine.paires morceaux [--cours batiments_proceduraux] [--par-etape N] [--graine G] [--etapes 1,2]
    python -m usine.paires bloc [--cours kart] [--par-etape N] [--graine G] [--etapes 1,2]
    python -m usine.paires test_cas [--cours kart] [--par-etape N] [--graine G] [--etapes 1,2]
    python -m usine.paires shader_fonction [--par-etape N] [--graine G] [--etapes 1,2]   (rend des images)
    python -m usine.paires assembler --palier 1|2 [--graine G]
    python -m usine.paires volume [--seulement creation,execution,...] [--cours kart,...]
"""

from __future__ import annotations

import argparse
import json
import sys


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parseur = argparse.ArgumentParser(prog="python -m usine.paires")
    sous = parseur.add_subparsers(dest="famille", required=True)
    p = sous.add_parser("camera", help="situer la caméra et les objets (voir_scene), cas vérifiés par deux rendus")
    p.add_argument("--niveaux", type=int, default=2)
    p.add_argument("--graine", type=int, default=1)
    p.add_argument("--paires", type=int, default=None, help="s'arrêter au niveau qui atteint P paires (niveaux devient un plafond)")
    e = sous.add_parser("editeur", help="lire l'éditeur Godot (voir_editeur) : où est quoi, quoi faire")
    e.add_argument("--niveaux", type=int, default=1)
    e.add_argument("--graine", type=int, default=1)
    e.add_argument("--paires", type=int, default=None, help="s'arrêter au niveau qui atteint P paires")
    tg = sous.add_parser("timing", help="timing : ce qu'on voit (capture_frames) contre la consigne chiffrée")
    tg.add_argument("--niveaux", type=int, default=1, help="nombre de jeux (graines) au plus")
    tg.add_argument("--graine", type=int, default=1)
    tg.add_argument("--paires", type=int, default=None, help="s'arrêter au jeu qui atteint P paires")
    for nom, aide in (("compilation", "erreur de compilation → ligne corrigée (code vérifié des cours)"),
                      ("shader", "erreur de shader → correction, compilée au rendu (code vérifié des cours)")):
        cp = sous.add_parser(nom, help=aide)
        cp.add_argument("--cours", default="kart", choices=["kart", "roguelike", "atelier", "batiments_proceduraux"])
        cp.add_argument("--par-etape", type=int, default=6)
        cp.add_argument("--graine", type=int, default=1)
        cp.add_argument("--etapes", default=None, help="numéros séparés par des virgules (défaut : toutes)")
    for nom, aide in (("execution", "erreur à l'exécution → correction (chemin de nœud, type du nœud)"),
                      ("creation", "écrire une fonction d'après son contrat ##, jugée par les tests de l'étape")):
        ex = sous.add_parser(nom, help=aide)
        ex.add_argument("--cours", default="kart", choices=["kart", "roguelike", "atelier", "batiments_proceduraux"])
        ex.add_argument("--par-etape", type=int, default=4)
        ex.add_argument("--graine", type=int, default=1)
        ex.add_argument("--etapes", default=None, help="numéros séparés par des virgules (défaut : toutes)")
    sous.add_parser("lecture", help="lire une sortie de Godot : verdict, erreur à traiter d'abord (tirée de B1, B2, B3)")
    sous.add_parser("rag", help="chercher dans le RAG par le Code Mode, puis employer ce qu'il rend (tirée des créations)")
    pt = sous.add_parser("points", help="réaliser un point de l'étape d'après sa description (tests rouges sans, verts avec)")
    pt.add_argument("--cours", default="kart", choices=["kart", "roguelike", "atelier"])
    pt.add_argument("--etapes", default=None, help="numéros séparés par des virgules (défaut : toutes)")
    mg = sous.add_parser("maillage", help="écrire une fonction d'un générateur de bâtiment, jugée par l'empreinte du maillage")
    mg.add_argument("--par-etape", type=int, default=30)
    mg.add_argument("--graine", type=int, default=1)
    mg.add_argument("--etapes", default=None, help="numéros séparés par des virgules (défaut : toutes)")
    mc = sous.add_parser("morceaux", help="écrire un changement d'un point de l'étape (bâtiments), jugé par le maillage")
    mc.add_argument("--cours", default="batiments_proceduraux", choices=["kart", "roguelike", "atelier", "batiments_proceduraux"])
    mc.add_argument("--par-etape", type=int, default=40)
    mc.add_argument("--graine", type=int, default=1)
    mc.add_argument("--etapes", default=None, help="numéros séparés par des virgules (défaut : toutes)")
    bl = sous.add_parser("bloc", help="écrire les lignes qui manquent à une fonction, jugées par les tests ou le maillage")
    bl.add_argument("--cours", default="kart", choices=["kart", "roguelike", "atelier", "batiments_proceduraux"])
    bl.add_argument("--par-etape", type=int, default=60)
    bl.add_argument("--graine", type=int, default=1)
    bl.add_argument("--etapes", default=None, help="numéros séparés par des virgules (défaut : toutes)")
    tc = sous.add_parser("test_cas", help="écrire un cas de test GdUnit4 qui juge vraiment le code (vidé, il échoue)")
    tc.add_argument("--cours", default="kart", choices=["kart", "roguelike", "atelier"])
    tc.add_argument("--par-etape", type=int, default=40)
    tc.add_argument("--graine", type=int, default=1)
    tc.add_argument("--etapes", default=None, help="numéros séparés par des virgules (défaut : toutes)")
    sf = sous.add_parser("shader_fonction", help="écrire une fonction de shader (bâtiments), jugée par l'image rendue")
    sf.add_argument("--par-etape", type=int, default=30)
    sf.add_argument("--graine", type=int, default=1)
    sf.add_argument("--etapes", default=None, help="numéros séparés par des virgules (défaut : toutes)")
    vol = sous.add_parser("volume", help="génération en volume, famille après famille, puis lectures et paliers")
    vol.add_argument("--seulement", default=None, help="familles séparées par des virgules (défaut : toutes)")
    vol.add_argument("--cours", default=None, help="cours séparés par des virgules (défaut : tous)")
    asm = sous.add_parser("assembler", help="jeu d'un palier : contrôles, 40/40/20 par sujet, format de LLaMA-Factory")
    asm.add_argument("--palier", type=int, required=True, choices=[1, 2])
    asm.add_argument("--graine", type=int, default=1)
    args = parseur.parse_args(argv)
    if args.famille == "camera":
        from usine.paires.camera import generer
        bilan = generer(args.niveaux, args.graine, cible=args.paires)
        print(json.dumps({k: v for k, v in bilan.items() if k != "rejets"}, ensure_ascii=False, indent=1))
        for r in bilan["rejets"]:
            print("rejet :", r)
        return 0 if bilan["paires"] else 1
    if args.famille == "editeur":
        from usine.paires.editeur import generer as generer_editeur
        bilan = generer_editeur(args.niveaux, args.graine, cible=args.paires)
        print(json.dumps({k: v for k, v in bilan.items() if k != "rejets"}, ensure_ascii=False, indent=1))
        for r in bilan["rejets"]:
            print("rejet :", r)
        return 0 if bilan["paires"] else 1
    if args.famille == "timing":
        from usine.paires.timing import generer as generer_timing
        bilan = generer_timing(args.niveaux, args.graine, cible=args.paires)
        print(json.dumps({k: v for k, v in bilan.items() if k != "rejets"}, ensure_ascii=False, indent=1))
        for r in bilan["rejets"]:
            print("rejet :", r)
        return 0 if bilan["paires"] else 1
    if args.famille in ("compilation", "shader"):
        from usine.paires.compilation import generer as generer_compilation
        etapes = [int(x) for x in args.etapes.split(",")] if args.etapes else None
        bilan = generer_compilation(args.cours, args.par_etape, args.graine, etapes, famille=args.famille)
        print(json.dumps({k: v for k, v in bilan.items() if k != "rejets"}, ensure_ascii=False, indent=1))
        for r in bilan["rejets"]:
            print("rejet :", r)
        return 0 if bilan["paires"] else 1
    if args.famille in ("execution", "creation"):
        if args.famille == "execution":
            from usine.paires.execution import generer as generer_famille
        else:
            from usine.paires.creation import generer as generer_famille
        etapes = [int(x) for x in args.etapes.split(",")] if args.etapes else None
        bilan = generer_famille(args.cours, args.par_etape, args.graine, etapes)
        print(json.dumps({k: v for k, v in bilan.items() if k != "rejets"}, ensure_ascii=False, indent=1))
        for r in bilan["rejets"]:
            print("rejet :", r)
        return 0 if bilan["paires"] else 1
    if args.famille == "rag":
        from usine.paires.rag import generer as generer_rag
        bilan = generer_rag()
        print(json.dumps({k: v for k, v in bilan.items() if k != "rejets"}, ensure_ascii=False, indent=1))
        return 0 if bilan["paires"] else 1
    if args.famille == "points":
        from usine.paires.points import generer as generer_points
        etapes = [int(x) for x in args.etapes.split(",")] if args.etapes else None
        bilan = generer_points(args.cours, etapes)
        print(json.dumps({k: v for k, v in bilan.items() if k != "rejets"}, ensure_ascii=False, indent=1))
        for r in bilan["rejets"]:
            print("rejet :", r)
        return 0 if bilan["paires"] else 1
    if args.famille in ("bloc", "test_cas"):
        if args.famille == "bloc":
            from usine.paires.bloc import generer as generer_bloc
        else:
            from usine.paires.test_cas import generer as generer_bloc
        etapes = [int(x) for x in args.etapes.split(",")] if args.etapes else None
        bilan = generer_bloc(args.cours, args.par_etape, args.graine, etapes)
        print(json.dumps({k: v for k, v in bilan.items() if k != "rejets"}, ensure_ascii=False, indent=1))
        for r in bilan["rejets"]:
            print("rejet :", r)
        return 0 if bilan["paires"] else 1
    if args.famille in ("maillage", "morceaux", "shader_fonction"):
        if args.famille == "maillage":
            from usine.paires.maillage import generer as generer_maillage
        elif args.famille == "morceaux":
            from usine.paires.morceaux import generer as generer_maillage
        else:
            from usine.paires.shader_fonction import generer as generer_maillage
        etapes = [int(x) for x in args.etapes.split(",")] if args.etapes else None
        bilan = (generer_maillage(args.cours, args.par_etape, args.graine, etapes) if args.famille == "morceaux"
                 else generer_maillage(args.par_etape, args.graine, etapes))
        print(json.dumps({k: v for k, v in bilan.items() if k != "rejets"}, ensure_ascii=False, indent=1))
        for r in bilan["rejets"]:
            print("rejet :", r)
        return 0 if bilan["paires"] else 1
    if args.famille == "volume":
        from usine.paires.volume import lancer
        lancer(args.seulement.split(",") if args.seulement else None,
               cours=args.cours.split(",") if args.cours else None)
        return 0
    if args.famille == "assembler":
        from usine.paires.assembler import assembler
        controles = assembler(args.palier, args.graine)
        print(json.dumps(controles, ensure_ascii=False, indent=1))
        return 0 if controles["paires"] and not controles["problemes"] else 1
    if args.famille == "lecture":
        from usine.paires.lecture import generer as generer_lecture
        bilan = generer_lecture()
        print(json.dumps(bilan, ensure_ascii=False, indent=1))
        return 0 if bilan["paires"] else 1
    return 2


if __name__ == "__main__":
    sys.exit(main())
