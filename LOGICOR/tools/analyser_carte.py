#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
analyser_carte.py
Analyse la carte de données de Hades II et extrait les informations pour Space Dracula.
"""

import json
import os
from pathlib import Path

# Chemins
CARTE_DIR = Path(r"F:\Hades II.wawacity.click\Hades II\Hades II\_GAME_MAP_v2 -generalise - convertie")
OUTPUT_DIR = Path(__file__).parent.parent / "space_dracula" / "donnees"


def charger_identity_map() -> dict:
    """Charge la carte d'identité des entités."""
    with open(CARTE_DIR / "identity_map.json", "r", encoding="utf-8") as f:
        return json.load(f)


def charger_props() -> list:
    """Charge les propriétés des entités."""
    props = []
    with open(CARTE_DIR / "props.jsonl", "r", encoding="utf-8") as f:
        for ligne in f:
            ligne = ligne.strip()
            if ligne:
                props.append(json.loads(ligne))
    return props


def charger_param_dictionary() -> list:
    """Charge le dictionnaire des paramètres."""
    with open(CARTE_DIR / "param_dictionary.json", "r", encoding="utf-8") as f:
        return json.load(f)


def categoriser_entities(identity: dict) -> dict:
    """Catégorise les entités par type."""
    categories = {}
    for name, info in identity.items():
        cat = info.get("categorie", "inconnu")
        if cat not in categories:
            categories[cat] = []
        categories[cat].append({
            "nom_original": name,
            "nom_affiche": info.get("nom_affiche_origine", name),
            "nom_actuel": info.get("nom_actuel", name),
        })
    return categories


def extraire_props_ennemis(props: list, identity: dict) -> dict:
    """Extrait les propriétés des ennemis."""
    ennemis = {}
    
    # Trouver tous les IDs d'ennemis
    ennemi_ids = set()
    for name, info in identity.items():
        if info.get("categorie") in ("ennemi", "boss", "mini-boss"):
            ennemi_ids.add(info.get("nom_actuel", name))
            ennemi_ids.add(name)
    
    # Extraire les props
    for p in props:
        id_ = p.get("id", "")
        # Vérifier si c'est un ennemi
        if id_ in ennemi_ids or any(e in id_ for e in ennemi_ids):
            ennemis[id_] = {
                "props": p.get("props", {}),
                "file": p.get("file", ""),
            }
    
    return ennemis


def generer_fiches_space_dracula(identity: dict, props: list) -> None:
    """Génère les fiches de données pour Space Dracula."""
    
    # Créer le dossier de sortie
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    categories = categoriser_entities(identity)
    
    # Générer les fiches ennemis
    ennemis_fiches = []
    for ennemi in categories.get("ennemi", []):
        fiche = {
            "nom": ennemi["nom_actuel"],
            "nom_original": ennemi["nom_affiche"],
            "categorie": "ennemi",
        }
        ennemis_fiches.append(fiche)
    
    # Générer les fiches boss
    boss_fiches = []
    for boss in categories.get("boss", []):
        fiche = {
            "nom": boss["nom_actuel"],
            "nom_original": boss["nom_affiche"],
            "categorie": "boss",
        }
        boss_fiches.append(fiche)
    
    # Générer les fiches mini-boss
    mini_boss_fiches = []
    for mini_boss in categories.get("mini-boss", []):
        fiche = {
            "nom": mini_boss["nom_actuel"],
            "nom_original": mini_boss["nom_affiche"],
            "categorie": "mini-boss",
        }
        mini_boss_fiches.append(fiche)
    
    # Écrire les fiches
    with open(OUTPUT_DIR / "FICHES_ENNEMIS.json", "w", encoding="utf-8") as f:
        json.dump(ennemis_fiches, f, indent=2, ensure_ascii=False)
    
    with open(OUTPUT_DIR / "FICHES_BOSSES.json", "w", encoding="utf-8") as f:
        json.dump(boss_fiches, f, indent=2, ensure_ascii=False)
    
    with open(OUTPUT_DIR / "FICHES_MINI_BOSSES.json", "w", encoding="utf-8") as f:
        json.dump(mini_boss_fiches, f, indent=2, ensure_ascii=False)
    
    # Générer le mapping de renommage
    mapping = {}
    for name, info in identity.items():
        mapping[name] = {
            "nom_space_dracula": info.get("nom_actuel", name),
            "categorie": info.get("categorie", "inconnu"),
        }
    
    with open(OUTPUT_DIR / "MAPPING_RENOMMAGE.json", "w", encoding="utf-8") as f:
        json.dump(mapping, f, indent=2, ensure_ascii=False)
    
    print("=== ANALYSE TERMINÉE ===")
    print(f"Ennemis: {len(ennemis_fiches)}")
    print(f"Bosses: {len(boss_fiches)}")
    print(f"Mini-boss: {len(mini_boss_fiches)}")
    print(f"Mapping: {len(mapping)} entités")
    print(f"Fichiers générés dans: {OUTPUT_DIR}")


def main():
    print("Chargement de la carte de données...")
    identity = charger_identity_map()
    print(f"  - identity_map: {len(identity)} entités")
    
    props = charger_props()
    print(f"  - props: {len(props)} enregistrements")
    
    params = charger_param_dictionary()
    print(f"  - param_dictionary: {len(params)} paramètres")
    
    print("\nGénération des fiches Space Dracula...")
    generer_fiches_space_dracula(identity, props)


if __name__ == "__main__":
    main()
