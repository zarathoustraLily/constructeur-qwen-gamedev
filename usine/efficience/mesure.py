"""Lancer le script de mesure (gd/mesurer_efficience.gd) sur un projet préparé.

    deterministe : allocations après l'échauffement, lots de dessin (médiane), signatures de rendu
    temps        : durée médiane d'une image dans la fenêtre (µs) — varie d'une exécution à l'autre

Godot tourne en `--headless --fixed-fps 60` : chaque image fait exactement un pas de physique
de 1/60 s, aussi vite que la machine le permet.
"""

from __future__ import annotations

import hashlib
import json
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable

from usine import config as cfg
from usine.juge import godot as juges
from usine.juge.cache import version_juge
from usine.juge.projet import preparer_copie
from usine.processus import executer

SCRIPT = Path(__file__).resolve().parent / "gd" / "mesurer_efficience.gd"
MARQUEUR = "@@USINE_EFFICIENCE@@"


@dataclass(frozen=True)
class Reglages:
    """Paramètres de la mesure (champ `mesure_efficience` de tache.json)."""
    scene: str = "res://scenes/jeu.tscn"
    echauffement: int = 60
    fin: int = 180
    images_rendu: tuple[int, ...] = (180, 240, 300)
    temps: bool = False
    executions_temps: int = 3

    @classmethod
    def depuis_tache(cls, mesure: dict[str, Any]) -> "Reglages":
        return cls(scene=mesure.get("scene", cls.scene), echauffement=int(mesure.get("echauffement", 60)),
                   fin=int(mesure.get("fin", 180)), images_rendu=tuple(mesure.get("images_rendu", (180, 240, 300))),
                   temps=bool(mesure.get("temps", False)))

    def arguments(self, mode: str) -> list[str]:
        rendu = ",".join(str(i) for i in self.images_rendu) if mode == "deterministe" else ""
        return [mode, self.scene, str(self.echauffement), str(self.fin), rendu]


class ErreurMesure(RuntimeError):
    pass


_VERSION: str | None = None


def version_efficience() -> str:
    """Empreinte du code qui mesure (ce paquet) et du juge commun : entre dans la clé du cache."""
    global _VERSION
    if _VERSION is None:
        h = hashlib.sha256(version_juge().encode("ascii"))
        racine = Path(__file__).resolve().parent
        for f in sorted((f for f in racine.rglob("*") if f.suffix in (".py", ".gd") and f.is_file()),
                        key=lambda f: f.relative_to(racine).parts):
            h.update(f"{f.relative_to(racine).as_posix()}\n".encode("utf-8"))
            h.update(f.read_bytes().replace(b"\r\n", b"\n"))
        _VERSION = h.hexdigest()[:16]
    return _VERSION


def lancer(projet: Path, reglages: Reglages, mode: str, delai_s: float | None = None) -> dict[str, Any]:
    """Une exécution du script de mesure sur `projet` (copie de travail déjà importée)."""
    res = executer([cfg.chemin_godot(), "--headless", "--fixed-fps", "60", "--path", projet, "-s", SCRIPT,
                    "--", *reglages.arguments(mode)], delai_s=delai_s if delai_s is not None else cfg.delai_juge())
    for ligne in res.sortie.splitlines():
        if ligne.startswith(MARQUEUR):
            return json.loads(ligne[len(MARQUEUR):])
    fin = "\n".join(res.sortie.splitlines()[-15:])
    raise ErreurMesure(f"la mesure n'a rien rendu (code {res.code}{', délai dépassé' if res.expire else ''}) :\n{fin}")


@dataclass
class Copie:
    """Copie de travail importée, prête pour plusieurs mesures ; détruite par `fermer`."""
    racine: Path
    projet: Path
    _tmp: Any = field(default=None, repr=False)

    @classmethod
    def ouvrir(cls, source: Path, superpositions: Iterable[Path] = ()) -> "Copie":
        tmp = tempfile.TemporaryDirectory(prefix="usine_efficience_")
        projet = preparer_copie(Path(source), Path(tmp.name) / "projet", superpositions)
        imp = juges.importer(projet)
        if not imp["ok"]:
            tmp.cleanup()
            raise ErreurMesure("import en échec : " + "; ".join(e["message"] for e in imp["erreurs"]))
        return cls(Path(tmp.name), projet, tmp)

    def fermer(self) -> None:
        if self._tmp is not None:
            self._tmp.cleanup()
            self._tmp = None

    def __enter__(self) -> "Copie":
        return self

    def __exit__(self, *exc) -> None:
        self.fermer()


def mediane(valeurs: list[float]) -> float:
    v = sorted(valeurs)
    if not v:
        return 0.0
    n = len(v)
    return float(v[n // 2]) if n % 2 else (v[n // 2 - 1] + v[n // 2]) / 2


def mesurer_deterministe(source: Path, superpositions: Iterable[Path], reglages: Reglages) -> dict[str, Any]:
    with Copie.ouvrir(source, superpositions) as c:
        return lancer(c.projet, reglages, "deterministe")


def mesurer_temps_croises(a: Copie, b: Copie, reglages: Reglages) -> tuple[list[float], list[float]]:
    """Durées médianes d'une image, exécutions alternées a, b, a, b… (le bruit de la machine
    touche les deux également)."""
    ta, tb = [], []
    for _ in range(reglages.executions_temps):
        ta.append(float(lancer(a.projet, reglages, "temps")["temps_image_us"]))
        tb.append(float(lancer(b.projet, reglages, "temps")["temps_image_us"]))
    return ta, tb


def contenu(source: Path, superpositions: Iterable[Path] = ()) -> str:
    """Empreinte du projet composé (mêmes règles que le cache des verdicts)."""
    from usine.juge.cache import _empreintes
    fichiers = _empreintes(Path(source), "", True)
    for sup in superpositions:
        fichiers.update(_empreintes(Path(sup), "", True))
    return hashlib.sha256(json.dumps(fichiers, sort_keys=True).encode("utf-8")).hexdigest()

