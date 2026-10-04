"""Exemples de code vérifiés pour le RAG : les démos officielles Godot 4.7.

Source : dépôt godotengine/godot-demo-projects au tag `4.7-6ad6167` (licence MIT), copie
locale indiquée par `[chemins].demos_godot`. Projets retenus : les 135 de la liste principale
de laurent (2026-10-04), c'est-à-dire tous les projets du tag sauf `mono/` (C#) et l'annexe
« compatibilité non confirmée » (misc/os_test, mobile/android_iap).

Vérification, sans LLM, par notre Godot 4.7.2, sur une copie jetable de chaque projet (la
copie locale des démos n'est jamais modifiée) : import, puis compilation de chaque script
(`gd/verifier_scripts.gd` : chargé et instanciable). « Vérifié » veut dire « compile sous
Godot 4.7.2 », pas « exécuté ». Seuls les scripts qui compilent entrent dans l'index, marqués
`exemple`. Le rapport (`verification_demos.json`, à côté de l'index) garde l'empreinte SHA-256
de chaque script : il n'est refait que si un script change, et un script modifié depuis sa
vérification n'entre pas dans l'index.

Découpage : un fragment « en-tête » par script (extends, class_name, signaux, variables,
constantes) puis un fragment par fonction (avec sa doc ##), précédés d'une ligne de contexte ;
le code hors fonctions (classes internes…) forme des fragments « suite ».
"""

from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import tempfile
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


def _sha256(chemin: Path) -> str:
    return hashlib.sha256(chemin.read_bytes()).hexdigest()


def empreintes_projet(dossier: Path) -> dict[str, str]:
    return {res: _sha256(Path(dossier) / res[len("res://"):]) for res in scripts_du_projet(dossier)}


def empreinte_depot(depot: Path, liste: list[str]) -> str:
    """Empreinte de tous les scripts retenus : le rapport n'est refait que si elle change."""
    h = hashlib.sha256()
    for projet in liste:
        for res, e in sorted(empreintes_projet(Path(depot) / projet).items()):
            h.update(f"{projet}\t{res}\t{e}\n".encode("utf-8"))
    return h.hexdigest()


def verifier_projet(dossier: Path, godot: Path | None = None) -> dict[str, Any]:
    """Copie le projet dans un dossier jetable, l'importe et compile chacun de ses scripts."""
    godot = godot or cfg.chemin_godot()
    debut = time.monotonic()
    empreintes = empreintes_projet(dossier)
    resultats: dict[str, bool] = {s: False for s in empreintes}
    with tempfile.TemporaryDirectory(prefix="usine_demo_") as tmp:
        copie = Path(tmp) / "projet"
        shutil.copytree(dossier, copie, ignore=shutil.ignore_patterns(".godot"))
        imp = executer([godot, "--headless", "--path", copie, "--import"], delai_s=900)
        scripts = sorted(empreintes)
        for i in range(0, len(scripts), LOT_SCRIPTS):
            lot = scripts[i:i + LOT_SCRIPTS]
            res = executer([godot, "--headless", "--path", copie, "-s", SCRIPT_VERIF, "--", *lot], delai_s=600)
            for ligne in res.sortie.splitlines():
                if ligne.startswith(MARQUEUR):
                    d = json.loads(ligne[len(MARQUEUR):])
                    if d["chemin"] in resultats:
                        resultats[d["chemin"]] = bool(d["ok"])
    return {"import_code": imp.code, "scripts": resultats, "empreintes": empreintes,
            "duree_s": round(time.monotonic() - debut, 1)}


def verifier_demos(depot: Path, rapport: Path, travailleurs: int = 2, godot: Path | None = None,
                   journal: Callable[[str], None] = print) -> dict[str, Any]:
    """Vérifie chaque projet retenu ; relit le rapport existant si les scripts n'ont pas changé."""
    depot = Path(depot)
    rapport = Path(rapport)
    liste = projets(depot)
    empreinte = empreinte_depot(depot, liste)
    if rapport.is_file():
        ancien = json.loads(rapport.read_text(encoding="utf-8"))
        if ancien.get("empreinte_scripts") == empreinte and ancien.get("godot") == cfg.version_godot():
            return ancien
    resultat: dict[str, Any] = {"revision": revision(depot), "tag": TAG_DEMOS, "godot": cfg.version_godot(),
                                "empreinte_scripts": empreinte, "projets": {}}

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
    couvert = fin_entete
    for f, d in zip(script.fonctions, debuts):
        if d > couvert:  # code de niveau 0 entre deux fonctions (classe interne, variables…)
            ajouter(f"{projet} › {nom_fichier} › (suite)", "\n".join(lignes[couvert:d]), None)
        ajouter(f"{projet} › {nom_fichier} › {f.nom}", "\n".join(lignes[d:f.ligne_fin]), f.nom)
        couvert = max(couvert, f.ligne_fin)
    if couvert < len(lignes):
        ajouter(f"{projet} › {nom_fichier} › (suite)", "\n".join(lignes[couvert:]), None)
    return fragments


def fragments_demos(depot: Path, verification: dict[str, Any]) -> tuple[list[Fragment], dict[str, int]]:
    """Fragments des scripts qui compilent ; compte des scripts retenus et écartés.

    Un script dont l'empreinte a changé depuis sa vérification est écarté (`scripts_modifies`).
    """
    depot = Path(depot)
    fragments: list[Fragment] = []
    compte = {"projets": 0, "scripts_verifies": 0, "scripts_ecartes": 0, "scripts_modifies": 0}
    for projet, r in sorted(verification["projets"].items()):
        compte["projets"] += 1
        empreintes = r.get("empreintes") or {}
        for res, ok in sorted(r["scripts"].items()):
            if not ok:
                compte["scripts_ecartes"] += 1
                continue
            fichier = depot / projet / res[len("res://"):]
            if not fichier.is_file() or _sha256(fichier) != empreintes.get(res):
                compte["scripts_modifies"] += 1
                continue
            fragments += fragments_script(projet, res, fichier.read_text(encoding="utf-8", errors="replace"))
            compte["scripts_verifies"] += 1
    return fragments, compte
