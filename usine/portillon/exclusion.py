"""Exclusion des jeux gelés, appliquée partout : entraînement, RAG, invention.

Trois portes, toutes lues depuis donnees/geles/manifeste.json :
- `tache_exclue(dossier)` : une tâche (générée ou inventée) qui double une tâche gelée
  (empreinte identique, ou fragments de réponse au-delà du seuil) ;
- `session_exclue(entete)` : une session enregistrée dont l'en-tête vise une tâche gelée
  (tache_id ou empreinte) ne part jamais à l'entraînement (session 5) ;
- `texte_exclu(texte)` : un document (page de doc pour le RAG, exemple d'entraînement) qui
  contient une part importante des fragments de la réponse ou de la consigne d'une tâche gelée.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

from usine import config as cfg
from usine.portillon.dedoublonnage import Index, fragments_texte, signature_tache
from usine.portillon.gel import lire_manifeste


class Exclusion:
    def __init__(self, manifeste: dict[str, Any] | None, seuil: float = 0.8, seuil_texte: float = 0.6):
        self.seuil_texte = seuil_texte
        self.index = Index(seuil)
        self.ids: set[str] = set()
        self.empreintes: set[str] = set()
        self.taches: list[dict[str, Any]] = []
        for comp, entree in ((manifeste or {}).get("competences") or {}).items():
            for t in entree["taches"]:
                sig = {"id": t["id"], "competence": comp, "empreinte": t["empreinte"], "fragments": t["fragments"]}
                self.index.ajouter(sig)
                self.ids.add(t["id"])
                self.empreintes.add(t["empreinte"])
                self.taches.append({"id": t["id"], "reponse": set(t["fragments"]),
                                    "consigne": set(t.get("fragments_consigne", []))})

    @classmethod
    def charger(cls, racine: Path | None = None, **options) -> "Exclusion":
        return cls(lire_manifeste(Path(racine) if racine else cfg.dossier_donnees()), **options)

    @classmethod
    def depuis_taches(cls, racine: Path, **options) -> "Exclusion":
        """Exclusion bâtie sur toutes les tâches d'un dossier (`tache.json`), gelées ou non.

        Sert de contrôle plus large que le gel : si aucun texte ne reprend une tâche candidate,
        aucun ne reprend une tâche gelée (le gel est tiré parmi elles).
        """
        from usine.portillon.dedoublonnage import signature_tache
        competences: dict[str, Any] = {}
        for fichier in sorted(Path(racine).rglob("tache.json")):
            sig = signature_tache(fichier.parent)
            competences.setdefault(sig["competence"], {"taches": []})["taches"].append(sig)
        return cls({"competences": competences}, **options)

    def __bool__(self) -> bool:
        return bool(self.ids)

    def tache_exclue(self, dossier: Path) -> tuple[str, str] | None:
        """(raison, id gelé) si la tâche double une tâche gelée."""
        return self.index.doublon(signature_tache(dossier))

    def session_exclue(self, entete: dict[str, Any]) -> bool:
        return entete.get("tache_id") in self.ids or entete.get("empreinte") in self.empreintes

    def texte_exclu(self, texte: str) -> str | None:
        """Id de la tâche gelée dont le texte reprend une part ≥ seuil_texte des fragments."""
        frag = fragments_texte(texte)
        if not frag:
            return None
        for t in self.taches:
            for cible in (t["reponse"], t["consigne"]):
                if len(cible) >= 4 and len(cible & frag) / len(cible) >= self.seuil_texte:
                    return t["id"]
        return None
