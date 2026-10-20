#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
verifier_tokens.py
Vérifie qu'il n'y a pas de collision entre les tokens originaux et les tokens LOGICOR.
"""

import csv
import re
from pathlib import Path

# Chemins
BASE = Path(__file__).parent.parent
INVENTAIRE = BASE / "INVENTAIRE.csv"

# Les 8 mots interdits
MOTS_INTERDITS = [
    "Hades",
    "Zagreus",
    "Tartarus",
    "Olympus",
    "Daedalus",
    "Melinoe",
    "Skoll",
    "Hydra",
]

# Les dossiers à scanner
DOSSIERS = [
    "acteurs",
    "adversaires",
    "donnees",
    "preuves",
    "systemes",
    "fiches",
    "ia_adversaire",
    "analyse",
    "conception",
]

# Extensions à scanner
EXTENSIONS = [".gd", ".tres", ".md", ".json", ".py"]


def charger_inventaire() -> set:
    """Charge l'inventaire des tokens originaux."""
    tokens = set()
    with open(INVENTAIRE, "r", encoding="utf-8") as f:
        lecteur = csv.DictReader(f)
        for ligne in lecteur:
            tokens.add(ligne["token"])
    return tokens


def scanner_tokens() -> set:
    """Scanne les fichiers LOGICOR et retourne les tokens trouvés."""
    tokens = set()
    
    # Fichiers à exclure (contiennent les tokens originaux par design).
    EXCLUS = {"INVENTAIRE.csv", "mapping.json"}
    
    for dossier in DOSSIERS:
        chemin = BASE / dossier
        if not chemin.exists():
            continue
        
        for fichier in chemin.rglob("*"):
            if fichier.suffix not in EXTENSIONS:
                continue
            if fichier.name in EXCLUS:
                continue
            
            try:
                contenu = fichier.read_text(encoding="utf-8")
            except Exception:
                continue
            
            # Extraire les identifiants (mots en PascalCase, snake_case, ou UPPER_CASE).
            for match in re.finditer(r'\b[A-Z][a-zA-Z0-9_]*\b', contenu):
                tokens.add(match.group())
            for match in re.finditer(r'\b[a-z_]+[a-z0-9_]*\b', contenu):
                tokens.add(match.group())
            for match in re.finditer(r'\b[A-Z][A-Z0-9_]*\b', contenu):
                tokens.add(match.group())
    
    # Scanner aussi les fichiers racine (hors exclusions).
    for fichier in BASE.iterdir():
        if fichier.is_file() and fichier.suffix in EXTENSIONS:
            if fichier.name in EXCLUS:
                continue
            try:
                contenu = fichier.read_text(encoding="utf-8")
            except Exception:
                continue
            for match in re.finditer(r'\b[A-Z][a-zA-Z0-9_]*\b', contenu):
                tokens.add(match.group())
            for match in re.finditer(r'\b[a-z_]+[a-z0-9_]*\b', contenu):
                tokens.add(match.group())
            for match in re.finditer(r'\b[A-Z][A-Z0-9_]*\b', contenu):
                tokens.add(match.group())
    
    return tokens


def verifier_mots_interdits() -> list:
    """Vérifie que les 8 mots interdits n'apparaissent pas."""
    trouvés = []
    
    # Fichiers à exclure.
    EXCLUS = {"INVENTAIRE.csv", "mapping.json", "ANTICLONE.md"}
    
    for dossier in DOSSIERS:
        chemin = BASE / dossier
        if not chemin.exists():
            continue
        
        for fichier in chemin.rglob("*"):
            if fichier.suffix not in EXTENSIONS:
                continue
            if fichier.name in EXCLUS:
                continue
            
            try:
                contenu = fichier.read_text(encoding="utf-8")
            except Exception:
                continue
            
            for mot in MOTS_INTERDITS:
                if mot.lower() in contenu.lower():
                    trouvés.append((fichier.name, mot))
    
    # Scanner aussi les fichiers racine.
    for fichier in BASE.iterdir():
        if fichier.is_file() and fichier.suffix in EXTENSIONS:
            if fichier.name in EXCLUS:
                continue
            try:
                contenu = fichier.read_text(encoding="utf-8")
            except Exception:
                continue
            for mot in MOTS_INTERDITS:
                if mot.lower() in contenu.lower():
                    trouvés.append((fichier.name, mot))
    
    return trouvés


def main():
    print("=== VÉRIFICATION ANTI-CLONE ===\n")
    
    # Charger l'inventaire.
    inventaire = charger_inventaire()
    print("Tokens originaux: %d" % len(inventaire))
    
    # Scanner les tokens LOGICOR.
    tokens_logicor = scanner_tokens()
    print("Tokens LOGICOR: %d" % len(tokens_logicor))
    
    # Vérifier les collisions.
    collisions = inventaire & tokens_logicor
    print("Collisions: %d" % len(collisions))
    
    if collisions:
        print("\nTokens en collision:")
        for token in sorted(collisions):
            print("  - %s" % token)
    
    # Vérifier les mots interdits.
    mots_trouvés = verifier_mots_interdits()
    print("Mots interdits trouvés: %d" % len(mots_trouvés))
    
    if mots_trouvés:
        print("\nMots interdits:")
        for fichier, mot in mots_trouvés:
            print("  - %s dans %s" % (mot, fichier))
    
    # Statut.
    if len(collisions) == 0 and len(mots_trouvés) == 0:
        print("Statut: OK")
    else:
        print("Statut: ÉCHEC")


if __name__ == "__main__":
    main()
