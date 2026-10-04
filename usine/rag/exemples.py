"""Exemples de code vérifiés pour le RAG : les démos officielles Godot 4.7.

Source : dépôt godotengine/godot-demo-projects au tag `4.7-6ad6167` (licence MIT), copie
locale indiquée par `[chemins].demos_godot`. Projets retenus : les 135 de la liste principale
de laurent (2026-10-04), c'est-à-dire tous les projets du tag sauf `mono/` (C#) et l'annexe
« compatibilité non confirmée » (misc/os_test, mobile/android_iap).

Vérification, sans LLM, par notre Godot 4.7.2 : import du projet, puis compilation de chaque
script (`gd/verifier_scripts.gd` : chargé et instanciable). Seuls les scripts qui compilent
entrent dans l'index, marqués `exemple` ; le rapport de vérification est gardé à côté de
l'index (`verification_demos.json`), indexé par la révision du dépôt pour ne pas la refaire.

Découpage : un fragment « en-tête » par script (extends, class_name, signaux, variables,
constantes) puis un fragment par fonction (avec sa doc ##), précédés d'une ligne de contexte.
"""

from __future__ import annotations

import json
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Any, Callable

from usine import config as cfg
from usine.processus import executer
from usine.rag.rst import Fragment

TAG_DEMOS = "4.7-6ad6167"
EXCLUS = ("mono/", "misc/os_test/", "mobile/android_iap/")
SCRIPT_VERIF = Path(__file__).resolve().parent / "gd" / "verifier_scripts.gd"
MARQUEUR = "@@RAG_SCRIPT@@"
TAILLE_MAX = 2000
LOT_SCRIPTS = 40


def chemin_demos(config: dict[str, Any] | None = None) -> Path | None:
    config = cfg.charger_config() if config is None else config
    valeur = config.get("chemins", {}).get("demos_godot")
    if not valeur or valeur == cfg.A_RENSEIGNER:
        return None
    chemin = Path(valeur).expanduser()
    return chemin if chemin.is_absolute() else cfg.RACINE / chemin


def revision(depot: Path) -> str:
    try:
        r = subprocess.run(["git", "-C", str(depot), "rev-parse", "HEAD"], capture_output=True, text=True, timeout=10)
        return r.stdout.strip() or "inconnue"
    except (OSError, subprocess.SubprocessError):
        return "inconnue"


def projets(depot: Path) -> list[str]:
    """Dossiers de projet retenus (posix, relatifs au dépôt), dans un ordre stable."""
    depot = Path(depot)
    trouves = []
    for p in sorted(depot.rglob("project.godot")):
        rel = p.parent.relative_to(depot).as_posix() + "/"
        if rel.startswith(EXCLUS) or any(part.startswith(".") for part in p.parent.relative_to(depot).parts):
            continue
        trouves.append(rel.rstrip("/"))
    return trouves


def scripts_du_projet(dossier: Path) -> list[str]:
    return sorted("res://" + p.relative_to(dossier).as_posix() for p in dossier.rglob("*.gd")
                  if ".godot" not in p.relative_to(dossier).parts)


def verifier_projet(dossier: Path, godot: Path | None = None) -> dict[str, Any]:
    """Importe le projet (dans son propre dossier : le .godot/ créé est un cache) et compile ses scripts."""
    godot = godot or cfg.chemin_godot()
    debut = time.monotonic()
    imp = executer([godot, "--headless", "--path", dossier, "--import"], delai_s=900)
    scripts = scripts_du_projet(dossier)
    resultats: dict[str, bool] = {s: False for s in scripts}
    for i in range(0, len(scripts), LOT_SCRIPTS):
        lot = scripts[i:i + LOT_SCRIPTS]
        res = executer([godot, "--headless", "--path", dossier, "-s", SCRIPT_VERIF, "--", *lot], delai_s=600)
        for ligne in res.sortie.splitlines():
            if ligne.startswith(MARQUEUR):
                d = json.loads(ligne[len(MARQUEUR):])
                resultats[d["chemin"]] = bool(d["ok"])
    return {"import_code": imp.code, "scripts": resultats, "duree_s": round(time.monotonic() - debut, 1)}


def verifier_demos(depot: Path, rapport: Path, travailleurs: int = 2, godot: Path | None = None,
                   journal: Callable[[str], None] = print) -> dict[str, Any]:
    """Vérifie chaque projet retenu ; relit le rapport existant s'il porte la même révision."""
    depot = Path(depot)
    rev = revision(depot)
    if rapport.is_file():
        ancien = json.loads(rapport.read_text(encoding="utf-8"))
        if ancien.get("revision") == rev and ancien.get("godot") == cfg.version_godot():
            return ancien
    liste = projets(depot)
    resultat: dict[str, Any] = {"revision": rev, "tag": TAG_DEMOS, "godot": cfg.version_godot(), "projets": {}}

    def un(projet: str) -> tuple[str, dict[str, Any]]:
        return projet, verifier_projet(depot / projet, godot)

    with ThreadPoolExecutor(max_workers=travailleurs) as pool:
        for projet, r in pool.map(un, liste):
            ok = sum(r["scripts"].values())
            journal(f"{projet:<45} {ok}/{len(r['scripts'])} scripts compilent  ({r['duree_s']} s)")
            resultat["projets"][projet] = r
    rapport.parent.mkdir(parents=True, exist_ok=True)
    rapport.write_text(json.dumps(resultat, ensure_ascii=False, indent=1, sort_keys=True) + "\n", encoding="utf-8")
    return resultat


def fragments_script(projet: str, res: str, texte: str) -> list[Fragment]:
    from usine.projet.gdscript import lire_script

    script = lire_script(texte, res)
    lignes = texte.splitlines()
    source = f"demos/{projet}/{res[len('res://'):]}"
    base = script.extends or "?"
    contexte = f"# démo officielle {projet} — {res}" + (f" — extends {base}" if script.extends else "") + \
               (f" — class_name {script.class_name}" if script.class_name else "")
    fragments: list[Fragment] = []

    def ajouter(titre: str, code: str, membre: str | None) -> None:
        code = code.strip("\n")
        if not code.strip():
            return
        if len(code) > TAILLE_MAX:
            code = code[:TAILLE_MAX].rsplit("\n", 1)[0] + "\n\t# […] (suite dans " + source + ")"
        fragments.append(Fragment(source, f"démo {projet}", titre, contexte + "\n" + code, "exemple",
                                  script.extends if script.extends and not script.extends.startswith(("\"", "'")) else None,
                                  membre))

    debuts = []
    for f in script.fonctions:
        d = f.ligne_debut
        while d > 0 and lignes[d - 1].lstrip().startswith(("##", "@")):
            d -= 1  # doc ## et annotations (@rpc…) au-dessus de la fonction
        debuts.append(d)
    fin_entete = min(debuts) if debuts else len(lignes)
    nom_fichier = res.rsplit("/", 1)[-1]
    ajouter(f"{projet} › {nom_fichier}", "\n".join(lignes[:fin_entete]), None)
    for f, d in zip(script.fonctions, debuts):
        ajouter(f"{projet} › {nom_fichier} › {f.nom}", "\n".join(lignes[d:f.ligne_fin]), f.nom)
    return fragments


def fragments_demos(depot: Path, verification: dict[str, Any]) -> tuple[list[Fragment], dict[str, int]]:
    """Fragments des scripts qui compilent ; compte des scripts retenus et écartés."""
    depot = Path(depot)
    fragments: list[Fragment] = []
    compte = {"projets": 0, "scripts_verifies": 0, "scripts_ecartes": 0}
    for projet, r in sorted(verification["projets"].items()):
        compte["projets"] += 1
        for res, ok in sorted(r["scripts"].items()):
            if not ok:
                compte["scripts_ecartes"] += 1
                continue
            fichier = depot / projet / res[len("res://"):]
            fragments += fragments_script(projet, res, fichier.read_text(encoding="utf-8", errors="replace"))
            compte["scripts_verifies"] += 1
    return fragments, compte
