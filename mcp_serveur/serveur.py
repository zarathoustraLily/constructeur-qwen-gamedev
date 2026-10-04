"""Serveur MCP « usine-godot » (stdio) : les outils déterministes et les juges pour OpenCode.

    python mcp_serveur/serveur.py [--projet <dossier du projet Godot>]

Sans --projet, le projet est le dossier courant (celui où OpenCode lance le serveur).
Lancé par chemin de fichier : le dépôt est ajouté à sys.path, aucune installation requise.
Descriptions courtes : chaque outil déclaré coûte des jetons de prompt à chaque tour.
"""

from __future__ import annotations

import argparse
import asyncio
import sys
from concurrent.futures import ThreadPoolExecutor
from functools import partial
from pathlib import Path
from typing import Any

RACINE = Path(__file__).resolve().parent.parent
if str(RACINE) not in sys.path:
    sys.path.insert(0, str(RACINE))

from mcp.server.fastmcp import FastMCP  # noqa: E402

from mcp_serveur.outils import Outils  # noqa: E402

NOM = "usine-godot"
INSTRUCTIONS = ("Outils Godot 4.7 déterministes sur le projet ouvert. Chemins en res://. "
                "Les écritures sont jugées sur une copie et appliquées seulement si le juge passe.")


def creer_serveur(projet: Path, godot: Path | None = None, index_docs: Path | None = None) -> FastMCP:
    outils = Outils(projet, godot, index_docs)
    mcp = FastMCP(NOM, instructions=INSTRUCTIONS)
    # Un seul fil d'exécution pour les outils : la boucle stdio reste disponible pendant qu'un
    # juge tourne, et les connexions SQLite (vocabulaire, index) restent dans le même fil.
    fil = ThreadPoolExecutor(max_workers=1, thread_name_prefix="usine-outils")

    async def executer(fonction, *args):
        return await asyncio.get_running_loop().run_in_executor(fil, partial(fonction, *args))

    outil = lambda description: mcp.tool(description=description, structured_output=False)  # noqa: E731

    @outil("Classe Godot réelle : héritage et membres propres ; avec membre, sa signature (héritage compris).")
    async def vocab_lookup(classe: str, membre: str | None = None) -> str:
        return await executer(outils.vocab_lookup, classe, membre)

    @outil("Cherche dans la doc Godot 4.7 et le code vérifié des démos officielles. "
           "source : tout|doc|exemples. Classe ou Classe.membre exact en tête.")
    async def search_docs(requete: str, n: int = 5, source: str = "tout") -> str:
        return await executer(outils.search_docs, requete, n, source)

    @outil("Lit une .tscn en spec JSON.")
    async def scene_read(chemin: str) -> str:
        return await executer(outils.scene_read, chemin)

    @outil("Écrit une .tscn depuis une spec JSON (format de scene_read), si elle se charge.")
    async def scene_write(chemin: str, spec: dict[str, Any]) -> str:
        return await executer(outils.scene_write, chemin, spec)

    @outil("Vue compacte du projet : scènes, nœuds avec leurs ids, scripts, connexions.")
    async def describe_project() -> str:
        return await executer(outils.describe_project)

    @outil("Applique une liste d'éditions (ops : add_node, del_node, set_property, attach_script, connect, "
           "disconnect, add_signal, add_function, replace_function, set_resource_value), tout ou rien.")
    async def apply_edits(edits: list[dict[str, Any]]) -> str:
        return await executer(outils.apply_edits, edits)

    @outil("Analyse un script .gd (erreurs de parse et de type).")
    async def check_script(chemin: str) -> str:
        return await executer(outils.check_script, chemin)

    @outil("Charge et instancie une scène en headless.")
    async def load_scene(chemin: str) -> str:
        return await executer(outils.load_scene, chemin)

    @outil("Lance les tests GdUnit4 (défaut res://tests ; ou un dossier, ou une suite).")
    async def run_tests(filtre: str | None = None) -> str:
        return await executer(outils.run_tests, filtre)

    return mcp


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="serveur.py")
    parser.add_argument("--projet", type=Path, default=Path.cwd())
    parser.add_argument("--godot", type=Path, default=None, help="binaire Godot console (défaut : config.toml)")
    parser.add_argument("--index", type=Path, default=None, help="index de documentation (défaut : donnees/rag)")
    args = parser.parse_args(argv)
    creer_serveur(args.projet, args.godot, args.index).run("stdio")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
