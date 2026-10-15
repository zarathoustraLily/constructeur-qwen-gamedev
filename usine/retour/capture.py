"""Voir le jeu tourner (béquille, point 8) : une grille d'images horodatées et le journal.

Lance le jeu, fenêtré, sur une copie du projet, avec --fixed-fps 60 (l'image N tombe à N/60 s
de jeu). L'autoload Capture (godot/socle_jeu/0_autoload/capture.gd) est posé dans la copie s'il
manque : la capture marche sur n'importe quel projet. Le journal Trace est joint s'il existe.
Le projet de l'utilisateur ne change pas (règle 7) ; seul notre processus est arrêté (règle 8).

Sous Linux sans écran (session cloud), le jeu passe par xvfb-run et le rendu de compatibilité.
"""

from __future__ import annotations

import os
import re
import shutil
import sys
import tempfile
import time
from pathlib import Path
from typing import Any, Iterable

from usine import config as cfg
from usine.processus import executer

SCRIPT_CAPTURE = cfg.RACINE / "godot" / "socle_jeu" / "0_autoload" / "capture.gd"
INJECTE = "res://addons/usine_capture/capture.gd"
IGNORES = shutil.ignore_patterns(".godot", "reports", "__pycache__", ".import")
_TOUCHE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*:\d+-\d+$")


def _poser_capture(copie: Path) -> None:
    projet_godot = copie / "project.godot"
    texte = projet_godot.read_text(encoding="utf-8")
    if re.search(r"^Capture=", texte, re.M):
        return
    cible = copie / INJECTE.removeprefix("res://")
    cible.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SCRIPT_CAPTURE, cible)
    ligne = f'Capture="*{INJECTE}"'
    if re.search(r"^\[autoload\]", texte, re.M):
        texte = re.sub(r"^\[autoload\]\s*\n", lambda m: m.group(0) + ligne + "\n", texte, count=1, flags=re.M)
    else:
        texte = texte.rstrip("\n") + f"\n\n[autoload]\n\n{ligne}\n"
    projet_godot.write_text(texte, encoding="utf-8")


def _prefixe_ecran() -> tuple[list[str], list[str]]:
    """(préfixe de commande, options Godot) selon qu'un écran existe ou non."""
    if sys.platform.startswith("linux") and not os.environ.get("DISPLAY") and shutil.which("xvfb-run"):
        return ["xvfb-run", "-a", "-s", "-screen 0 1280x720x24"], ["--rendering-method", "gl_compatibility"]
    return [], []


def capturer(projet: Path, images: Iterable[int], scene: str | None = None, touches: Iterable[str] = (),
             sortie: Path | None = None, colonnes: int = 4, echelle: float = 0.5, godot: Path | None = None,
             delai_s: float = 180) -> dict[str, Any]:
    """{ok, grille (chemin du PNG ou None), legende (texte), duree_s, erreur?}."""
    from usine.juge.godot import importer
    images = sorted({int(i) for i in images if int(i) > 0})
    touches = [t for t in touches if _TOUCHE.match(t)]
    if not images:
        return {"ok": False, "grille": None, "legende": "", "erreur": "aucune image demandée (entiers > 0)"}
    sortie = Path(sortie) if sortie else Path(tempfile.gettempdir()) / "usine_captures"
    sortie.mkdir(parents=True, exist_ok=True)
    png = sortie / f"capture_{time.strftime('%Y%m%d_%H%M%S')}_{os.getpid()}.png"
    godot = Path(godot) if godot else cfg.chemin_godot()
    with tempfile.TemporaryDirectory(prefix="usine_capture_") as tmp:
        copie = Path(tmp) / "projet"
        shutil.copytree(projet, copie, ignore=IGNORES)
        _poser_capture(copie)
        importer(copie, godot)
        prefixe, options = _prefixe_ecran()
        commande = [*prefixe, godot, "--path", copie, *options, "--fixed-fps", "60",
                    *([scene] if scene else []), "--", f"--capture={png}",
                    "--capture-frames=" + ",".join(map(str, images)), f"--capture-cols={max(1, colonnes)}",
                    f"--capture-scale={echelle}", *(f"--capture-press={t}" for t in touches)]
        res = executer(commande, delai_s=delai_s)
    legende_f = Path(str(png) + ".txt")
    legende = legende_f.read_text(encoding="utf-8") if legende_f.is_file() else ""
    resultat = {"ok": bool(legende), "grille": str(png) if png.is_file() else None, "legende": legende,
                "duree_s": res.duree_s}
    if not legende:
        erreurs = [l for l in res.sortie.splitlines() if "ERROR" in l or "SCRIPT ERROR" in l][:5]
        resultat["erreur"] = ("délai dépassé" if res.expire else "aucune légende écrite") + \
            (" : " + " | ".join(erreurs) if erreurs else "")
    return resultat
