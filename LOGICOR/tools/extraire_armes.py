#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
extraire_armes.py
Extrait les données d'armes de la carte de données.
"""

import json
from pathlib import Path

CARTE_DIR = Path(r"F:\Hades II.wawacity.click\Hades II\Hades II\_GAME_MAP_v2 -generalise - convertie")
OUTPUT_DIR = Path(__file__).parent.parent / "space_dracula" / "donnees"


def main():
    # Charger identity_map pour trouver les armes
    with open(CARTE_DIR / "identity_map.json", "r", encoding="utf-8") as f:
        identity = json.load(f)
    
    # Charger props.jsonl
    with open(CARTE_DIR / "props.jsonl", "r", encoding="utf-8") as f:
        props = [json.loads(line) for line in f if line.strip()]
    
    # Trouver les armes dans identity_map
    armes_identity = {}
    for name, info in identity.items():
        if info.get("categorie") == "arme":
            armes_identity[info.get("nom_actuel", name)] = {
                "nom_original": info.get("nom_affiche_origine", name),
                "nom_actuel": info.get("nom_actuel", name),
            }
    
    print("=== ARMES (identity_map) ===")
    for nom_actuel, info in sorted(armes_identity.items()):
        print("%s -> %s" % (nom_actuel, info["nom_original"]))
    
    # Trouver les props des armes (Weapon*)
    weapon_props = []
    for p in props:
        id_ = p.get("id", "")
        if id_.startswith("Weapon") or "weapon" in id_.lower():
            weapon_props.append(p)
    
    print("\n=== PROPS ARMES ===")
    print("Trouvé %d props d'armes" % len(weapon_props))
    for p in weapon_props[:5]:
        keys = list(p.get("props", {}).keys())[:8]
        print("%s: %s" % (p["id"], keys))
    
    # Écrire les données
    with open(OUTPUT_DIR / "ARMES_IDENTITY.json", "w", encoding="utf-8") as f:
        json.dump(armes_identity, f, indent=2, ensure_ascii=False)
    
    with open(OUTPUT_DIR / "PROPS_ARMES.json", "w", encoding="utf-8") as f:
        json.dump(weapon_props, f, indent=2, ensure_ascii=False)
    
    print("\nÉcrit dans: %s" % OUTPUT_DIR)


if __name__ == "__main__":
    main()
