"""Preuve du serveur MCP : un client MCP (stdio) appelle list_tools puis chaque outil.

    python -m mcp_serveur.preuve [--projet godot/reference]

Le projet est d'abord copié dans un dossier jetable : scene_write et apply_edits y écrivent.
Contrôles : 9 outils déclarés ; chaque appel réussit ; un appel faux est refusé proprement
(chemin hors du projet, édition invalide) sans rien écrire.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import shutil
import sys
import tempfile
import time
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
OUTILS = ["vocab_lookup", "search_docs", "scene_read", "scene_write", "describe_project", "apply_edits",
          "check_script", "load_scene", "run_tests"]


async def _preuve(projet: Path, index: Path | None = None) -> list[tuple[str, bool, str]]:
    from mcp import ClientSession, StdioServerParameters
    from mcp.client.stdio import stdio_client

    lignes: list[tuple[str, bool, str]] = []
    params = StdioServerParameters(command=sys.executable,
                                   args=[str(RACINE / "mcp_serveur" / "serveur.py"), "--projet", str(projet)]
                                   + (["--index", str(index)] if index else []))
    async with stdio_client(params, errlog=open(Path(tempfile.gettempdir()) / "usine_mcp_preuve.log", "w")) as (r, w):
        async with ClientSession(r, w) as s:
            await s.initialize()
            outils = (await s.list_tools()).tools
            noms = [t.name for t in outils]
            taille = sum(len(json.dumps(t.model_dump(exclude_none=True), ensure_ascii=False)) for t in outils)
            lignes.append(("list_tools", sorted(noms) == sorted(OUTILS), f"{len(noms)} outils, {taille} caractères déclarés"))

            async def appel(nom: str, args: dict, attendu, resume) -> str:
                t = time.monotonic()
                res = await s.call_tool(nom, args)
                texte = res.content[0].text if res.content else ""
                try:
                    ok = attendu(res.isError, texte)
                except Exception:
                    ok = False
                lignes.append((nom, ok, f"{time.monotonic() - t:5.1f} s  " + (resume(texte) if ok else texte[:160])))
                return texte

            def verdict(champ="ok"):
                return lambda err, t: not err and json.loads(t)[champ] is True

            await appel("vocab_lookup", {"classe": "Area2D", "membre": "body_entered"},
                        lambda e, t: not e and "body_entered(body: Node2D)" in t, lambda t: t)
            await appel("search_docs", {"requete": "CharacterBody2D", "n": 3},
                        lambda e, t: not e and t.startswith("## CharacterBody2D  (classes/class_characterbody2d.rst)"),
                        lambda t: "1er : " + t.splitlines()[0][3:])
            spec_txt = await appel("scene_read", {"chemin": "res://scenes/coin.tscn"},
                                   lambda e, t: not e and json.loads(t)["racine"]["type"] == "Area2D",
                                   lambda t: f"racine {json.loads(t)['racine']['nom']} ({json.loads(t)['racine']['type']})")
            spec = json.loads(spec_txt)
            spec["racine"]["nom"] = "Piece2"
            await appel("scene_write", {"chemin": "res://scenes/piece2.tscn", "spec": spec},
                        lambda e, t: verdict()(e, t) and (projet / "scenes" / "piece2.tscn").is_file(),
                        lambda t: "écrite, load_scene ok")
            await appel("describe_project", {}, lambda e, t: not e and "SCÈNE piece2 = res://scenes/piece2.tscn" in t,
                        lambda t: f"{len(t.splitlines())} lignes, piece2 présente")
            edit = [{"op": "set_property", "noeud": "coin:CollisionShape2D", "propriete": "position",
                     "valeur": {"Vector2": [1, 2]}}]
            await appel("apply_edits", {"edits": edit}, lambda e, t: verdict()(e, t) and json.loads(t)["applique"],
                        lambda t: f"appliqué, tests {json.loads(t)['tests']['passes']}/{json.loads(t)['tests']['total']}")
            await appel("check_script", {"chemin": "res://scripts/hero.gd"}, verdict(), lambda t: "ok")
            await appel("load_scene", {"chemin": "res://scenes/main.tscn"}, verdict(), lambda t: "ok")
            await appel("run_tests", {}, verdict(),
                        lambda t: f"{json.loads(t)['tests']['passes']}/{json.loads(t)['tests']['total']} tests verts")
            # Refus propres.
            avant = (projet / "scenes" / "coin.tscn").read_bytes()
            await appel("apply_edits", {"edits": [{"op": "set_property", "noeud": "coin:Inexistant",
                                                   "propriete": "position", "valeur": {"Vector2": [0, 0]}}]},
                        lambda e, t: not e and json.loads(t)["etape"] == "validation" and not json.loads(t)["applique"]
                        and (projet / "scenes" / "coin.tscn").read_bytes() == avant,
                        lambda t: "refusé à la validation, projet intact")
            await appel("check_script", {"chemin": "../secret.gd"}, lambda e, t: e and "hors du projet" in t,
                        lambda t: "chemin hors du projet refusé")
    return lignes


def preuve(source: Path, index: Path | None = None) -> int:
    with tempfile.TemporaryDirectory(prefix="usine_mcp_") as tmp:
        projet = Path(tmp) / "projet"
        shutil.copytree(source, projet, ignore=shutil.ignore_patterns(".godot"))
        lignes = asyncio.run(_preuve(projet, index))
    for nom, ok, detail in lignes:
        print(f"{nom:<17} {'OK ' if ok else 'ÉCHEC'}  {detail}")
    tout = all(ok for _, ok, _ in lignes) and len(lignes) == 12
    print(f"{sum(ok for _, ok, _ in lignes)}/{len(lignes)} contrôles conformes")
    return 0 if tout else 1


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(prog="python -m mcp_serveur.preuve")
    parser.add_argument("--projet", type=Path, default=RACINE / "godot" / "reference")
    parser.add_argument("--index", type=Path, default=None)
    args = parser.parse_args(argv)
    return preuve(args.projet, args.index)


if __name__ == "__main__":
    raise SystemExit(main())
