"""Chemins de la machine pour la base : lus dans config.toml, remplaçables en ligne de commande.

- `[chemins].docs_godot` : copie du dépôt godot-docs (citations de la documentation, relues mot pour mot) ;
- `[chemins].source_godot` : copie du dépôt godot à l'étiquette 4.7.2-stable (référence des classes, table des
  renommages de Godot 3 à Godot 4) ;
- `[entrainement].vocab_qwen` : models/ggml-vocab-qwen35.gguf de llama.cpp (compte des jetons de Qwen) ;
  `[entrainement].vocab_qwen2` (facultatif) : models/ggml-vocab-qwen2.gguf, pour un second compte ;
- l'API de Godot vient de donnees/vocab (extraite du binaire par `python -m usine.vocab construire`).
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

from usine import config as cfg
from usine.cours import dossier_cours, dossier_projets

COURS = "batiments_proceduraux"


class CheminManquant(RuntimeError):
    """Un chemin nécessaire n'est pas renseigné, ou n'existe pas."""


@dataclass
class Chemins:
    cours: Path
    projets: Path
    base: Path
    docs: Path | None
    source_godot: Path | None
    vocab: Path | None
    vocab_qwen2: Path | None
    api: Path

    def _exige(self, chemin: Path | None, cle: str) -> Path:
        if chemin is None or not chemin.exists():
            raise CheminManquant(f"{cle} : chemin absent ou introuvable ({chemin}) ; le renseigner dans config.toml "
                                 "ou en ligne de commande")
        return chemin

    @property
    def docs_godot(self) -> Path:
        return self._exige(self.docs, "[chemins].docs_godot")

    @property
    def classes(self) -> Path:
        return self._exige(self.source_godot, "[chemins].source_godot") / "doc" / "classes"

    @property
    def gdscript_xml(self) -> Path:
        return self._exige(self.source_godot, "[chemins].source_godot") / "modules/gdscript/doc_classes/@GDScript.xml"

    @property
    def renommages(self) -> Path:
        chemin = self._exige(self.source_godot, "[chemins].source_godot") / "editor/project_upgrade/renames_map_3_to_4.cpp"
        return self._exige(chemin, "[chemins].source_godot (editor/project_upgrade/renames_map_3_to_4.cpp)")

    @property
    def vocab_qwen(self) -> Path:
        return self._exige(self.vocab, "[entrainement].vocab_qwen")

    @property
    def etapes(self) -> Path:
        """Un fichier JSON par étape : ses exemples de création et ses sessions de débogage (reprise possible)."""
        return self.base / "etapes"

    @property
    def livraison(self) -> Path:
        return self.base / "livraison"

    @property
    def travail(self) -> Path:
        """Les projets matérialisés pour lancer Godot (jetables)."""
        return self.base / "travail"

    @property
    def rendus(self) -> Path:
        return self.base / "rendus"


def _chemin(valeur: Any) -> Path | None:
    if not valeur or valeur == cfg.A_RENSEIGNER:
        return None
    chemin = Path(str(valeur)).expanduser()
    return chemin if chemin.is_absolute() else cfg.RACINE / chemin


_ACTUELS: Chemins | None = None


def configurer(docs: Path | str | None = None, source_godot: Path | str | None = None,
               vocab: Path | str | None = None, vocab_qwen2: Path | str | None = None,
               config: dict[str, Any] | None = None) -> Chemins:
    """Fixe les chemins : ceux passés ici, sinon ceux de config.toml."""
    global _ACTUELS
    from usine.vocab.construire import chemin_json
    config = cfg.charger_config() if config is None else config
    chem = config.get("chemins", {})
    entr = config.get("entrainement", {})
    base = cfg.dossier_donnees(config) / "cours" / COURS / "base"
    _ACTUELS = Chemins(
        cours=dossier_cours(COURS),
        projets=dossier_projets(COURS, config),
        base=base,
        docs=_chemin(docs) or _chemin(chem.get("docs_godot")),
        source_godot=_chemin(source_godot) or _chemin(chem.get("source_godot")),
        vocab=_chemin(vocab) or _chemin(entr.get("vocab_qwen")),
        vocab_qwen2=_chemin(vocab_qwen2) or _chemin(entr.get("vocab_qwen2")),
        api=chemin_json(config),
    )
    return _ACTUELS


def actuels() -> Chemins:
    return _ACTUELS if _ACTUELS is not None else configurer()
