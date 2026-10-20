#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
extraire_props_bosses.py
Extrait les propriétés des boss de la carte de données.
"""

import json
from pathlib import Path

CARTE_DIR = Path(r"F:\Hades II.wawacity.click\Hades II\Hades II\_GAME_MAP_v2 -generalise - convertie")
OUTPUT_DIR = Path(__file__).parent.parent / "space_dracula" / "donnees"


def main():
    with open(CARTE_DIR / "props.jsonl", "r", encoding="utf-8") as f:
        props = [json.loads(line) for line in f if line.strip()]
    
    # Trouver les props des boss
    boss_props = []
    for p in props:
        id_ = p.get("id", "")
        if "boss-" in id_.lower():
            boss_props.append(p)
    
    print("Trouvé %d props de boss" % len(boss_props))
    for p in boss_props[:10]:
        keys = list(p.get("props", {}).keys())[:5]
        print("%s: %s" % (p["id"], keys))
    
    # Écrire dans un fichier
    with open(OUTPUT_DIR / "PROPS_BOSSES.json", "w", encoding="utf-8") as f:
        json.dump(boss_props, f, indent=2, ensure_ascii=False)
    
    print("Écrit dans: %s" % (OUTPUT_DIR / "PROPS_BOSSES.json"))


if __name__ == "__main__":
    main()
