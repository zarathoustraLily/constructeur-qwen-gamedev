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


def creer_serveur(projet: Path, godot: Path | None = None, index_docs: Path | None = None,
                  observation: Path | None = None) -> FastMCP:
    outils = Outils(projet, godot, index_docs, observation)
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

    @outil("Analyse un script .gd (erreurs de parse et de type) et vérifie chaque classe et membre Godot "
           "qu'il utilise, avec leurs signatures officielles. À appeler après chaque écriture de script.")
    async def check_script(chemin: str) -> str:
        return await executer(outils.check_script, chemin)

    @outil("Charge et instancie une scène en headless ; en cas d'erreur, la fiche du membre en cause.")
    async def load_scene(chemin: str) -> str:
        return await executer(outils.load_scene, chemin)

    @outil("Lance les tests GdUnit4 (défaut res://tests, ou res://7_tests ; ou un dossier, ou une suite) ; "
           "en cas d'erreur, la fiche du membre en cause.")
    async def run_tests(filtre: str | None = None) -> str:
        return await executer(outils.run_tests, filtre)

    @outil("Vérifie le projet selon ORGANISATION.md : chaque fichier dans son dossier, chaque dossier ne "
           "référence que ceux qu'il a le droit de connaître, et les règles mécaniques (typage, syntaxe Godot 4, "
           "nommage, valeurs dans 5_data, présentation dans _view, entrées dans _input, temps, hasard). "
           "Chaque écart nomme sa règle par son identifiant.")
    async def check_structure() -> str:
        return await executer(outils.check_structure)

    @outil("Avant d'agir : déclare ton but, le type d'ajout (etat, ennemi, arme, reglage, interface, niveau, "
           "effet_visuel, autre), les fichiers prévus et les besoins cochés dans la liste fermée (minuterie, etat, "
           "collision, son, effet_visuel, animation, interface, donnees, camera, sauvegarde) ; situations "
           "facultatives (ennemi_touche, mort_acteur, tir, apparition_ennemis, fin_de_niveau). Rend en une fois "
           "où travailler, l'exemple à imiter et une fiche par besoin : à considérer, API, exemple, pièges, voisins.")
    async def prepare_action(but: str, type_action: str, fichiers: list[str], besoins: list[str],
                             situations: list[str] | None = None) -> str:
        return await executer(outils.prepare_action, but, type_action, fichiers, besoins, situations)

    @outil("Lance le jeu (copie, fenêtré, 60 images/s) et rend une grille d'images horodatées avec, pour "
           "chaque case, ce que le journal a noté (états, coups, score). touches : « action:de-à » en images, "
           "ex. move_up:10-70. Défaut : scène principale.")
    async def capture_frames(images: list[int], scene: str | None = None, touches: list[str] | None = None) -> str:
        return await executer(outils.capture_frames, images, scene, touches)

    @outil("Voir la scène 3D comme dans l'éditeur (copie, rendu) à l'image N : vue du jeu, vues de dessus, côté, "
           "face, 3/4 avec le champ de la caméra (jaune), les objets dans le champ (vert) ou hors champ (rouge), axes "
           "et noms ; carte en texte : caméra (position, visée), chaque objet et pourquoi il est hors champ. "
           "vues : jeu,dessus,cote,face,perspective ; cadrer : un nœud ; collisions : formes de collision.")
    async def voir_scene(scene: str | None = None, image: int = 60, vues: list[str] | None = None,
                         cadrer: str | None = None, collisions: bool = False) -> str:
        return await executer(outils.voir_scene, scene, image, vues, cadrer, collisions)

    @outil("Mesure d'efficience (copie, headless) : allocations après échauffement, lots de dessin, "
           "empreinte du rendu aux images 180/240/300, temps indicatif. Défaut : scène principale.")
    async def measure_efficiency(scene: str | None = None) -> str:
        return await executer(outils.measure_efficiency, scene)

    if observation is not None:
        # Déclaré pour les tâches O1 seulement : chaque outil déclaré coûte des jetons à chaque tour.
        @outil("Joue une séquence scriptée du jeu (sans fenêtre ; défaut : toutes) : règles de partie cassées "
               "(gravité, hauteur, sous le sol, traversée, enfouissement, caméra), à quelle image, et le parcours.")
        async def play_sequence(sequence: str | None = None) -> str:
            return await executer(outils.play_sequence, sequence)

    return mcp


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="serveur.py")
    parser.add_argument("--projet", type=Path, default=Path.cwd())
    parser.add_argument("--godot", type=Path, default=None, help="binaire Godot console (défaut : config.toml)")
    parser.add_argument("--index", type=Path, default=None, help="index de documentation (défaut : donnees/rag)")
    parser.add_argument("--observation", type=Path, default=None,
                        help="matériel d'observation d'une tâche O1 (config.json, monde_verite.tscn) : déclare play_sequence")
    args = parser.parse_args(argv)
    creer_serveur(args.projet, args.godot, args.index, args.observation).run("stdio")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
