#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
from pathlib import Path

CARTE_DIR = Path(r"F:\Hades II.wawacity.click\Hades II\Hades II\_GAME_MAP_v2 -generalise - convertie")
GRAPH_FILE = CARTE_DIR / "graph.jsonl"
IDENTITY_MAP_FILE = CARTE_DIR / "identity_map.json"

# Charger l'identity map pour trouver les armes
identity_map = json.load(open(IDENTITY_MAP_FILE, encoding="utf-8"))
armes = {k: v for k, v in identity_map.items() if v.get("categorie") == "arme"}
print(f"Armes: {len(armes)}")
print("Premières 3:", list(armes.keys())[:3])

# Chercher les nœuds d'armes dans graph.jsonl
with open(GRAPH_FILE, "r", encoding="utf-8") as f:
    for i, line in enumerate(f):
        try:
            node = json.loads(line)
            node_id = node.get("id", "")
            # Chercher un nœud qui correspond à une arme
            for arme_id in armes:
                if arme_id in node_id or node_id in arme_id:
                    print(f"\nNœud {i+1}: {node_id}")
                    print(json.dumps(node, indent=2, ensure_ascii=False)[:800])
                    break
        except:
            pass
        if i > 100:
            break
