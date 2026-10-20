#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generer_fiches_armes.py
Génère les fiches des 34 armes Space Dracula.
Les armes sont des buffs/passifs sans props dans la carte.
"""

import json
from pathlib import Path

CARTE_DIR = Path(r"F:\Hades II.wawacity.click\Hades II\Hades II\_GAME_MAP_v2 -generalise - convertie")
IDENTITY_MAP_FILE = CARTE_DIR / "identity_map.json"
MAPPING_FILE = Path(__file__).parent.parent / "space_dracula" / "donnees" / "MAPPING_SPACE_DRACULA.json"
OUTPUT_DIR = Path(__file__).parent.parent / "space_dracula" / "fiches"


def charger_mapping() -> dict:
    with open(MAPPING_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def charger_identity_map() -> dict:
    with open(IDENTITY_MAP_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def main():
    print("Chargement des données...")
    mapping = charger_mapping()
    identity_map = charger_identity_map()
    
    # Extraire les armes
    armes = []
    for key, value in identity_map.items():
        if isinstance(value, dict) and value.get("categorie") == "arme":
            # Trouver le nom Space Dracula dans le mapping
            nom_sd = mapping.get(key, {}).get("nom_sd", f"REL-{value.get('numero', 0):03d}")
            armes.append({
                "id": nom_sd,
                "nom": nom_sd,
                "categorie": "arme",
                "numero": value.get("numero", 0),
                "props": {},  # Les armes sont des buffs/passifs, pas de props dans la carte
            })
    
    # Trier par numéro
    armes.sort(key=lambda x: x["numero"])
    
    # Écrire les fiches
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output_file = OUTPUT_DIR / "FICHES_ARMES_V2.json"
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(armes, f, indent=2, ensure_ascii=False)
    
    print(f"\n=== FICHES ARMES GÉNÉRÉES ===")
    print(f"  Total: {len(armes)}")
    for fiche in armes[:5]:
        print(f"    {fiche['id']}")
    
    print(f"\nÉcrit dans: {output_file}")


if __name__ == "__main__":
    main()
