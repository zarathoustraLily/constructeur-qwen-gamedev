"""Lance un projet Godot avec le rendu réel pendant quelques secondes et en garde des captures d'écran.

    py -3.12 outils/capture_godot.py <dossier du projet> [--secondes 5] [--scene res://x.tscn]
                                     [--sortie <dossier>] [--images 2]

Affiche le chemin des images PNG (une par ligne, préfixe « IMAGE »), puis les erreurs et
avertissements écrits par le moteur pendant l'exécution. Aucune touche n'est appuyée : le jeu
tourne seul. Par défaut les images vont dans <projet>/.captures/ (ignoré par Godot : .gdignore).

Godot tourne en mode « movie maker » (--write-movie) : une fenêtre s'ouvre, le jeu est rendu
image par image à 30 images/s, puis Godot se ferme. Le processus est le nôtre : au-delà du délai
il est coupé par son PID (règle 8).
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
if str(RACINE) not in sys.path:
    sys.path.insert(0, str(RACINE))

from usine import config as cfg  # noqa: E402

IPS = 30
MAX_SECONDES = 20.0
MAX_CAR_JOURNAL = 3000
MOTS_JOURNAL = ("ERROR", "WARNING", "Parse Error", "   at: ", "   at ", "GDScript backtrace")


def _couper(processus: subprocess.Popen) -> None:
    if sys.platform == "win32":      # le binaire console lance le moteur en processus fils
        subprocess.run(["taskkill", "/PID", str(processus.pid), "/T", "/F"], capture_output=True)
    else:
        processus.kill()


def journal_moteur(sortie: str) -> str:
    """Lignes d'erreur et d'avertissement du moteur, plafonnées."""
    lignes = [l.rstrip() for l in sortie.splitlines() if any(m in l for m in MOTS_JOURNAL)]
    texte = "\n".join(lignes)
    return texte if len(texte) <= MAX_CAR_JOURNAL else texte[:MAX_CAR_JOURNAL] + "\n[…tronqué]"


def capturer(projet: Path, secondes: float = 5.0, scene: str | None = None, sortie: Path | None = None,
             images: int = 2, prefixe: str | None = None) -> tuple[list[tuple[float, Path]], str]:
    """Renvoie ([(instant en s, image PNG)], journal du moteur). Liste vide si rien n'a été rendu."""
    projet = Path(projet).resolve()
    secondes = max(1.0, min(float(secondes), MAX_SECONDES))
    n = int(round(secondes * IPS))
    if sortie is None:
        sortie = projet / ".captures"
        sortie.mkdir(exist_ok=True)
        (sortie / ".gdignore").touch()
    sortie = Path(sortie)
    sortie.mkdir(parents=True, exist_ok=True)
    prefixe = prefixe or time.strftime("%Y%m%d-%H%M%S")
    with tempfile.TemporaryDirectory(prefix="capture_godot_") as tmp:
        commande = [str(cfg.chemin_godot()), "--path", str(projet), "--fixed-fps", str(IPS),
                    "--write-movie", str(Path(tmp) / "i.png"), "--quit-after", str(n)]
        if scene:
            commande.append(scene)
        processus = subprocess.Popen(commande, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        try:
            brut, _ = processus.communicate(timeout=secondes * 6 + 90)
        except subprocess.TimeoutExpired:
            _couper(processus)
            brut, _ = processus.communicate()
            brut += b"\nERROR: delai depasse, Godot a ete coupe (boucle infinie ou chargement bloque ?)"
        texte = brut.decode("utf-8", errors="replace")
        rendues = sorted(Path(tmp).glob("i*.png"))
        gardees: list[tuple[float, Path]] = []
        if rendues:
            images = max(1, min(int(images), 4))
            for k in range(1, images + 1):
                indice = min(len(rendues) - 1, max(0, round(len(rendues) * k / images) - 1))
                instant = round((indice + 1) / IPS, 1)
                cible = sortie / f"{prefixe}_t{instant:04.1f}s.png"
                shutil.copyfile(rendues[indice], cible)
                gardees.append((instant, cible))
    journal = journal_moteur(texte)
    if not gardees:
        fin = [l for l in texte.splitlines() if l.strip()][-8:]
        journal = ((journal + "\n" if journal else "") + "ERROR: aucune image rendue (le projet ne démarre pas)."
                   + "\nDernières lignes de Godot :\n" + "\n".join(fin))
    return gardees, journal


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    p = argparse.ArgumentParser(prog="capture_godot.py")
    p.add_argument("projet", type=Path)
    p.add_argument("--secondes", type=float, default=5.0)
    p.add_argument("--scene")
    p.add_argument("--sortie", type=Path)
    p.add_argument("--images", type=int, default=2)
    a = p.parse_args(argv)
    if not (a.projet / "project.godot").is_file():
        print(f"pas de project.godot dans {a.projet}", file=sys.stderr)
        return 2
    gardees, journal = capturer(a.projet, a.secondes, a.scene, a.sortie, a.images)
    for instant, image in gardees:
        print(f"IMAGE t={instant} s : {image}")
    print("Journal du moteur (erreurs et avertissements) :\n" + (journal or "(rien)"))
    return 0 if gardees else 1


if __name__ == "__main__":
    raise SystemExit(main())
