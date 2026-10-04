"""Vocabulaire Godot exact : extension_api.json → SQLite, et vocab_lookup."""

from usine.vocab.construire import chemin_base, construire
from usine.vocab.requete import GENRES, Vocabulaire, existe, ouvrir

__all__ = ["GENRES", "Vocabulaire", "chemin_base", "construire", "existe", "ouvrir"]
