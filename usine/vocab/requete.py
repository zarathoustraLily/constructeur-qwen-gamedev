"""Requêtes sur le vocabulaire Godot, en suivant l'héritage."""

from __future__ import annotations

import sqlite3
from functools import lru_cache
from pathlib import Path

from usine.vocab.construire import PORTEE_GLOBALE, chemin_base, construire

# genre → (table, colonne du nom)
GENRES = {
    "methode": ("methodes", "nom"),
    "signal": ("signaux", "nom"),
    "propriete": ("proprietes", "nom"),
    "constante": ("constantes", "nom"),
    "enum": ("enums", "nom"),
    "valeur_enum": ("enum_valeurs", "nom"),
}


class Vocabulaire:
    """Accès en lecture seule à la base SQLite du vocabulaire."""

    def __init__(self, base: Path):
        self.base = Path(base)
        self.db = sqlite3.connect(f"file:{self.base.as_posix()}?mode=ro", uri=True)
        self.db.row_factory = sqlite3.Row

    def version(self) -> str:
        ligne = self.db.execute("SELECT valeur FROM meta WHERE cle='version'").fetchone()
        return ligne[0] if ligne else "?"

    def classe_existe(self, classe: str) -> bool:
        return self.db.execute("SELECT 1 FROM classes WHERE nom=?", (classe,)).fetchone() is not None

    def heritage(self, classe: str) -> list[str]:
        """Chaîne d'héritage, de la classe elle-même jusqu'à la racine. Vide si inconnue."""
        chaine: list[str] = []
        courante: str | None = classe
        while courante and courante not in chaine:
            ligne = self.db.execute("SELECT parent FROM classes WHERE nom=?", (courante,)).fetchone()
            if ligne is None:
                break
            chaine.append(courante)
            courante = ligne["parent"]
        return chaine

    def definie_dans(self, classe: str, membre: str, genre: str | None = None) -> str | None:
        """Classe (dans la chaîne d'héritage) qui définit le membre, ou None."""
        genres = [genre] if genre else list(GENRES)
        for g in genres:
            if g not in GENRES:
                raise ValueError(f"genre inconnu : {g!r} (attendu : {', '.join(GENRES)})")
        for c in self.heritage(classe):
            for g in genres:
                table, colonne = GENRES[g]
                if self.db.execute(f"SELECT 1 FROM {table} WHERE classe=? AND {colonne}=?", (c, membre)).fetchone():
                    return c
        return None

    def existe(self, classe: str, membre: str, genre: str | None = None) -> bool:
        return self.definie_dans(classe, membre, genre) is not None

    def arite(self, classe: str, methode: str) -> tuple[int, int | None] | None:
        """(arguments obligatoires, maximum ; None si vararg) d'une méthode, héritage compris."""
        origine = self.definie_dans(classe, methode, "methode")
        if origine is None:
            return None
        m = self.db.execute("SELECT * FROM methodes WHERE classe=? AND nom=?", (origine, methode)).fetchone()
        return m["nb_args_obligatoires"], (None if m["vararg"] else m["nb_args"])

    def _membres(self, classe: str, requete: str) -> list[dict]:
        resultat = []
        for c in self.heritage(classe):
            for ligne in self.db.execute(requete, (c,)):
                d = dict(ligne)
                d["origine"] = c
                resultat.append(d)
        return resultat

    def signaux(self, classe: str) -> list[dict]:
        resultat = self._membres(classe, "SELECT nom FROM signaux WHERE classe=? ORDER BY nom")
        for s in resultat:
            s["arguments"] = [
                dict(a) for a in self.db.execute(
                    "SELECT nom, type FROM signal_arguments WHERE classe=? AND signal=? ORDER BY position",
                    (s["origine"], s["nom"]))
            ]
        return resultat

    def proprietes(self, classe: str) -> list[dict]:
        return self._membres(classe, "SELECT nom, type FROM proprietes WHERE classe=? ORDER BY nom")

    def methodes(self, classe: str) -> list[dict]:
        resultat = self._membres(classe, "SELECT nom, retour, statique, virtuelle, vararg FROM methodes WHERE classe=? ORDER BY nom")
        for m in resultat:
            m["arguments"] = [
                dict(a) for a in self.db.execute(
                    "SELECT nom, type, defaut FROM arguments WHERE classe=? AND methode=? ORDER BY position",
                    (m["origine"], m["nom"]))
            ]
        return resultat

    def constantes(self, classe: str) -> list[dict]:
        return self._membres(classe, "SELECT nom, valeur FROM constantes WHERE classe=? ORDER BY nom")

    def enums(self, classe: str) -> list[dict]:
        resultat = self._membres(classe, "SELECT nom, bitfield FROM enums WHERE classe=? ORDER BY nom")
        for e in resultat:
            e["valeurs"] = [
                dict(v) for v in self.db.execute(
                    "SELECT nom, valeur FROM enum_valeurs WHERE classe=? AND enum=? ORDER BY valeur, nom",
                    (e["origine"], e["nom"]))
            ]
        return resultat

    def decrire(self, classe: str) -> dict:
        return {
            "classe": classe,
            "version": self.version(),
            "heritage": self.heritage(classe),
            "signaux": self.signaux(classe),
            "proprietes": self.proprietes(classe),
            "methodes": self.methodes(classe),
            "constantes": self.constantes(classe),
            "enums": self.enums(classe),
        }


@lru_cache(maxsize=4)
def _ouvrir(base: str) -> Vocabulaire:
    return Vocabulaire(Path(base))


def ouvrir(base: Path | None = None, construire_si_absente: bool = True) -> Vocabulaire:
    """Ouvre la base du vocabulaire (la construit depuis Godot si elle manque)."""
    base = Path(base) if base else chemin_base()
    if not base.is_file():
        if not construire_si_absente:
            raise FileNotFoundError(f"vocabulaire absent : {base} (lancer `python -m usine.vocab construire`)")
        base = construire()
    return _ouvrir(str(base.resolve()))


def existe(classe: str, membre: str, genre: str | None = None, base: Path | None = None) -> bool:
    """Vrai si `classe` (ou un de ses ancêtres) définit `membre` du genre donné.

    genre : "methode", "signal", "propriete", "constante", "enum", "valeur_enum" ou None (tous).
    """
    return ouvrir(base).existe(classe, membre, genre)


__all__ = ["GENRES", "PORTEE_GLOBALE", "Vocabulaire", "existe", "ouvrir"]
