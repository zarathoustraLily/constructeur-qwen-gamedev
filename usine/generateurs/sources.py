"""Projets sources de l'usine : où ils sont, et combien de candidates chacun peut fournir.

- reference : le jeu 2D de la session 1, réglages de la session 3 inchangés (tâches identiques).
- survivor : « 01-survivor » de Brock-Chain (MIT), bullet heaven 2D, 128 tests portés de GUT.
- kenney_platformer, kenney_racing : starter kits 3D de Kenney (code MIT, assets CC0), tests
  GdUnit4 écrits pour l'usine.
Origine, licence et retouches de chaque jeu : godot/<nom>/SOURCE.md.

Plafonds : un gros projet donnerait des centaines de candidates, jugées chacune une douzaine de
fois. On en tire au plus tant par générateur (graine fixe), et `ciblee` écarte d'avance ce
qu'aucun test ne peut voir (commun.fichiers_testes) ; le portillon reste le seul juge.
F1 n'existe que pour le héros de godot/reference (mesure en frames de usine/generateurs/inverse.py).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

from usine import config as cfg


@dataclass(frozen=True)
class Source:
    nom: str
    plafonds: dict[str, int | None] = field(default_factory=dict)  # générateur → plafond (None : tout)
    ciblee: bool = False
    scenes_generees: bool = False   # scènes générées de la session 2 (écrites pour godot/reference)
    f1: bool = False

    @property
    def chemin(self) -> Path:
        return cfg.RACINE / "godot" / self.nom

    def plafond(self, generateur: str) -> int | None:
        return self.plafonds.get(generateur)


SOURCES: tuple[Source, ...] = (
    Source("reference", scenes_generees=True, f1=True),
    Source("survivor", ciblee=True, plafonds={"k2": 40, "k1": 10, "s1": 8, "s2": 10, "mutation": 90}),
    Source("kenney_platformer", ciblee=True, plafonds={"k2": 25, "k1": 9, "s1": 8, "s2": 10, "mutation": 60}),
    Source("kenney_racing", ciblee=True, plafonds={"k2": 25, "k1": 3, "s1": 4, "s2": 10, "mutation": 60}),
)


def par_nom(noms: list[str] | None = None) -> list[Source]:
    if not noms:
        return list(SOURCES)
    connues = {s.nom: s for s in SOURCES}
    inconnues = [n for n in noms if n not in connues]
    if inconnues:
        raise ValueError(f"sources inconnues : {inconnues} (connues : {sorted(connues)})")
    return [connues[n] for n in noms]
