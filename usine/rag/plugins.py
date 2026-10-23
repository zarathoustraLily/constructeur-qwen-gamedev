"""Plugins conseillés par le RAG (décision 9 de laurent) : manifeste, fiche, exemple minimal vérifié par Godot 4.7.2.

`rag/plugins/plugins.toml` décrit chaque plugin retenu : dépôt, version, archive (adresse et SHA-256), dossiers de
l'addon dans l'archive, autoloads que le plugin pose quand on l'active dans l'éditeur. `rag/plugins/<id>/fiche.md` est
la fiche que lit le RAG ; `rag/plugins/<id>/exemple/` contient l'exemple minimal (`exemple.gd`, et d'autres fichiers
au besoin).

Vérifier un plugin : l'archive, téléchargée dans `donnees/plugins/archives/<id>/`, doit avoir l'empreinte du
manifeste. Un projet temporaire reçoit l'addon, l'exemple, les autoloads et le bloc `[debug]` strict du socle
(règle 5.3 ; les avertissements de `res://addons` restent exclus, réglage par défaut de 4.7.2,
`debug/gdscript/warnings/directory_rules`). Godot l'importe, puis lance l'exemple à cadence fixe. L'exemple réussit
s'il écrit « EXEMPLE VERIFIE » et si la sortie ne contient ni erreur ni avertissement (règle 5.5).

    python -m usine.rag.plugins verifier [id …]
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib
import zipfile
from pathlib import Path
from typing import Any, Iterable

from usine import config as cfg

DOSSIER = cfg.RACINE / "rag" / "plugins"
MARQUE = "EXEMPLE VERIFIE"
IMAGES_MAX = 600
# lignes de la machine, sans lien avec le projet (règle 5.1)
MACHINE = re.compile(r"^Godot Engine v|V-Sync|Shader cache|Failed to load cached shader|_load_from_cache")
PROBLEME = re.compile(r"^\s*(SCRIPT ERROR|USER ERROR|ERROR|USER WARNING|WARNING|Parse Error)\b")


def manifeste() -> dict[str, dict[str, Any]]:
    with open(DOSSIER / "plugins.toml", "rb") as f:
        return tomllib.load(f)


def archive(ident: str, entree: dict[str, Any], donnees: Path | None = None) -> Path:
    return Path(donnees or cfg.dossier_donnees()) / "plugins" / "archives" / ident / entree["fichier"]


def bloc_debug() -> str:
    """Le bloc [debug] du socle : les avertissements de GDScript traités en erreurs, typage compris."""
    texte = (cfg.RACINE / "godot" / "socle_jeu" / "project.godot").read_text(encoding="utf-8")
    debut = texte.index("[debug]")
    fin = texte.find("\n[", debut + 1)
    return texte[debut:fin if fin >= 0 else None].strip() + "\n"


def type_racine(script: str) -> str:
    """La classe que l'exemple étend : la racine de la scène de lancement."""
    m = re.search(r"^extends\s+(\w+)", script, re.M)
    return m.group(1) if m else "Node"


def problemes(sortie: str, connues: Iterable[str] = ()) -> list[str]:
    """Les lignes d'erreur et d'avertissement, hors lignes propres à la machine et hors lignes connues du plugin
    (`sorties_connues` du manifeste : messages exacts que le plugin écrit lui-même, expliqués dans sa fiche)."""
    connues = set(connues)
    return [l.strip() for l in sortie.splitlines()
            if PROBLEME.match(l) and not MACHINE.search(l) and l.strip() not in connues]


def reussi(code: int, sortie: str, connues: Iterable[str] = ()) -> bool:
    return code == 0 and MARQUE in sortie and not problemes(sortie, connues)


def preparer(ident: str, entree: dict[str, Any], projet: Path, donnees: Path | None = None) -> None:
    """Le projet de vérification : addon, exemple, scène de lancement, autoloads, bloc [debug] strict."""
    chemin = archive(ident, entree, donnees)
    empreinte = hashlib.sha256(chemin.read_bytes()).hexdigest()
    if empreinte != entree["sha256"]:
        raise ValueError(f"{ident} : empreinte {empreinte} au lieu de {entree['sha256']} ({chemin})")
    with tempfile.TemporaryDirectory() as tmp:
        with zipfile.ZipFile(chemin) as z:
            z.extractall(tmp)
        for dossier in entree["addons"]:
            source = Path(tmp) / dossier
            shutil.copytree(source, projet / "addons" / source.name)
    shutil.copytree(DOSSIER / ident / "exemple", projet / "exemple")
    script = (projet / "exemple" / "exemple.gd").read_text(encoding="utf-8")
    (projet / "exemple" / "main.tscn").write_text(
        '[gd_scene format=3]\n\n[ext_resource type="Script" path="res://exemple/exemple.gd" id="1"]\n\n'
        f'[node name="Exemple" type="{type_racine(script)}"]\nscript = ExtResource("1")\n', encoding="utf-8")
    autoloads = "".join(f'{k}="{v}"\n' for k, v in entree.get("autoloads", {}).items())
    (projet / "project.godot").write_text(
        f'config_version=5\n\n[application]\n\nconfig/name="exemple {ident}"\n'
        'config/features=PackedStringArray("4.7")\n\n'
        + (f"[autoload]\n\n{autoloads}\n" if autoloads else "") + bloc_debug(), encoding="utf-8")


def lancer(arguments: list[str], delai: float = 300) -> tuple[int, str]:
    godot = str(cfg.chemin_godot())
    for _ in range(3):  # deux éditeurs lancés ensemble se disputent leurs réglages : on relance
        p = subprocess.run([godot, *arguments], capture_output=True, text=True, encoding="utf-8", errors="replace",
                           timeout=delai)
        sortie = p.stdout + p.stderr
        if "Could not load editor settings" not in sortie:
            break
    return p.returncode, sortie


def verifier(ident: str, entree: dict[str, Any], donnees: Path | None = None) -> dict[str, Any]:
    projet = Path(donnees or cfg.dossier_donnees()) / "plugins" / "travail" / ident
    if projet.exists():
        shutil.rmtree(projet)
    preparer(ident, entree, projet, donnees)
    for _ in range(2):  # Godot 4.7.2 plante parfois en sortant de l'import (0xC0000005), sans message : on relance
        code, sortie = lancer(["--headless", "--path", str(projet), "--import"])
        if code < 0xC0000000 or problemes(sortie):
            break
    if code != 0 or problemes(sortie):
        return {"id": ident, "ok": False, "etape": "import", "code": code, "lignes": problemes(sortie)[:20]}
    code, sortie = lancer(["--headless", "--path", str(projet), "--fixed-fps", "60", "--quit-after",
                           str(IMAGES_MAX), "res://exemple/main.tscn"])
    marque = next((l.strip() for l in sortie.splitlines() if MARQUE in l), None)
    connues = entree.get("sorties_connues", [])
    return {"id": ident, "ok": reussi(code, sortie, connues), "etape": "exemple", "code": code, "marque": marque,
            "lignes": problemes(sortie, connues)[:20]}


def main(argv: list[str] | None = None) -> int:
    parseur = argparse.ArgumentParser(prog="python -m usine.rag.plugins")
    sous = parseur.add_subparsers(dest="commande", required=True)
    p_v = sous.add_parser("verifier", help="lancer l'exemple de chaque plugin dans Godot 4.7.2")
    p_v.add_argument("ids", nargs="*")
    args = parseur.parse_args(argv)
    plugins = manifeste()
    ids = args.ids or list(plugins)
    bilans = []
    for ident in ids:
        b = verifier(ident, plugins[ident])
        bilans.append(b)
        print(f"{ident} : {'ok' if b['ok'] else 'ÉCHEC à l’étape ' + b['etape']} {b.get('marque') or ''}")
        for ligne in b["lignes"]:
            print("    " + ligne)
    sortie = cfg.dossier_donnees() / "plugins" / "verification.json"
    sortie.parent.mkdir(parents=True, exist_ok=True)
    sortie.write_text(json.dumps(bilans, indent=1, ensure_ascii=False), encoding="utf-8")
    reussis = sum(b["ok"] for b in bilans)
    print(f"{reussis}/{len(bilans)} exemples vérifiés ; bilan : {sortie}")
    return 0 if reussis == len(bilans) else 1


if __name__ == "__main__":
    sys.exit(main())
