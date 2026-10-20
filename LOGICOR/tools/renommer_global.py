#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
renommer_global.py
Renomme globalement les tokens dans les fichiers .gd et .tres.
"""

import os
import re
import json
from pathlib import Path

# Chemins
BASE = Path(__file__).parent.parent
MAPPING_FILE = BASE / "tools" / "mapping.json"

# Les dossiers à scanner
DOSSIERS = [
    "acteurs",
    "adversaires",
    "donnees",
    "preuves",
    "systemes",
    "fiches",
]

# Extensions à scanner
EXTENSIONS = [".gd", ".tres"]


def charger_mapping() -> dict:
    """Charge le mapping des tokens."""
    with open(MAPPING_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)
    return data["mapping"]


def scanner_fichier(fichier: Path, mapping: dict) -> int:
    """Scanne un fichier et remplace les tokens. Retourne le nombre de remplacements."""
    try:
        contenu = fichier.read_text(encoding="utf-8")
    except Exception as e:
        print("Erreur: %s" % e)
        return 0
    
    original = contenu
    compteur = 0
    
    # Remplacer les tokens (du plus long au plus court pour éviter les conflits).
    for ancien, nouveau in sorted(mapping.items(), key=lambda x: len(x[0]), reverse=True):
        # Utiliser des mots entiers pour éviter les fausses détections.
        pattern = r'\b' + re.escape(ancien) + r'\b'
        if re.search(pattern, contenu):
            contenu = re.sub(pattern, nouveau, contenu)
            compteur += 1
    
    # Écrire si changement.
    if contenu != original:
        fichier.write_text(contenu, encoding="utf-8")
        print("Renommé: %s (%d tokens)" % (fichier.name, compteur))
    
    return compteur


def main():
    # Charger le mapping.
    mapping = charger_mapping()
    print("Mapping chargé: %d tokens" % len(mapping))
    
    # Scanner les dossiers.
    total = 0
    for dossier in DOSSIERS:
        chemin = BASE / dossier
        if not chemin.exists():
            continue
        
        for fichier in chemin.rglob("*"):
            if fichier.suffix in EXTENSIONS:
                total += scanner_fichier(fichier, mapping)
    
    print("\n=== %d tokens renommés ===" % total)


if __name__ == "__main__":
    main()
