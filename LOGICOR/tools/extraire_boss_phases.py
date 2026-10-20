#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
extraire_boss_phases.py
Extrait les phases et données des boss de la carte de données.
"""

import json
from pathlib import Path

CARTE_DIR = Path(r"F:\Hades II.wawacity.click\Hades II\Hades II\_GAME_MAP_v2 -generalise - convertie")
OUTPUT_DIR = Path(__file__).parent.parent / "space_dracula" / "donnees"


def main():
    # Charger identity_map
    with open(CARTE_DIR / "identity_map.json", "r", encoding="utf-8") as f:
        identity = json.load(f)
    
    # Charger props.jsonl
    with open(CARTE_DIR / "props.jsonl", "r", encoding="utf-8") as f:
        props = [json.loads(line) for line in f if line.strip()]
    
    # Charger graph.jsonl
    with open(CARTE_DIR / "graph.jsonl", "r", encoding="utf-8") as f:
        graph = [json.loads(line) for line in f if line.strip()]
    
    # Trouver les boss
    boss_ids = []
    for name, info in identity.items():
        if info.get("categorie") in ("boss", "mini-boss"):
            boss_ids.append(info.get("nom_actuel", name))
    
    print("=== BOSSESS ET MINI-BOSSES ===")
    for bid in sorted(boss_ids):
        print(bid)
    
    # Trouver les props liés aux boss
    boss_related_props = []
    for p in props:
        id_ = p.get("id", "")
        for bid in boss_ids:
            if bid in id_:
                boss_related_props.append(p)
                break
    
    print("\n=== PROPS LIÉS AUX BOSSES ===")
    print("Trouvé %d props" % len(boss_related_props))
    
    # Regrouper par boss
    boss_data = {}
    for p in boss_related_props:
        id_ = p.get("id", "")
        for bid in boss_ids:
            if bid in id_:
                if bid not in boss_data:
                    boss_data[bid] = []
                boss_data[bid].append(p)
                break
    
    for bid in sorted(boss_data.keys()):
        print("\n--- %s ---" % bid)
        for p in boss_data[bid]:
            print("  %s: %s" % (p["id"], list(p.get("props", {}).keys())[:6]))
    
    # Écrire les données
    with open(OUTPUT_DIR / "BOSSES_DATA.json", "w", encoding="utf-8") as f:
        json.dump(boss_data, f, indent=2, ensure_ascii=False)
    
    print("\nÉcrit dans: %s" % (OUTPUT_DIR / "BOSSES_DATA.json"))


if __name__ == "__main__":
    main()
