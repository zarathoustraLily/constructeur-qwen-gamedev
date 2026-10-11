"""Écritures de fichiers qui disent si elles ont changé quelque chose."""

from __future__ import annotations

from pathlib import Path


class Ecritures:
    """Écrit un fichier texte, sauf si son contenu est déjà celui demandé.

    Compte les écritures identiques d'affilée par fichier : c'est le signal qui manquait à
    Qwen pour voir qu'il tourne en rond (57 % des écritures des campagnes du 2026-10-09).
    """

    def __init__(self) -> None:
        self.repetitions: dict[str, int] = {}

    def ecrire(self, disque: Path, res: str, contenu: str) -> tuple[bool, str]:
        """Renvoie (changé, message)."""
        if disque.is_file():
            with disque.open(encoding="utf-8", newline="") as f:
                avant = f.read()
            if avant == contenu:
                n = self.repetitions.get(res, 0) + 1
                self.repetitions[res] = n
                fois = f" ({n} écritures identiques d'affilée)" if n > 1 else ""
                return False, (f"aucun changement : ce contenu est déjà celui de {res}{fois}. "
                               "Le fichier est enregistré ; passe à l'étape suivante.")
        self.repetitions[res] = 0
        disque.parent.mkdir(parents=True, exist_ok=True)
        with disque.open("w", encoding="utf-8", newline="") as f:
            f.write(contenu)
        return True, f"écrit : {res} ({len(contenu)} caractères)"
