#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
from pathlib import Path

CARTE_DIR = Path(r"F:\Hades II.wawacity.click\Hades II\Hades II\_GAME_MAP_v2 -generalise - convertie")
GRAPH_FILE = CARTE_DIR / "graph.jsonl"
IDENTITY_MAP_FILE = CARTE_DIR / "identity_map.json"

# Charger l'identity map
identity_map = json.load(open(IDENTITY_MAP_FILE, encoding="utf-8"))
armes = {k: v for k, v in identity_map.items() if v.get("categorie") == "arme"}

# Charger graph.jsonl et chercher les types de nœuds
types_nodes = {}
with open(GRAPH_FILE, "r", encoding="utf-8") as f:
    for line in f:
        try:
            node = json.loads(line)
            node_type = node.get("type", "unknown")
            types_nodes[node_type] = types_nodes.get(node_type, 0) + 1
        except:
            pass

print("Types de nœuds dans graph.jsonl:")
for k, v in sorted(types_nodes.items()):
    print(f"  {k}: {v}")

# Chercher les nœuds avec "weapon" dans l'id ou la catégorie
with open(GRAPH_FILE, "r", encoding="utf-8") as f:
    for i, line in enumerate(f):
        if i > 500:
            break
        try:
            node = json.loads(line)
            node_id = node.get("id", "").lower()
            category = node.get("category", "").lower()
            if "weapon" in node_id or "weapon" in category:
                print(f"\nNœud {i+1}: {node.get('id')} (type: {node.get('type')}, cat: {node.get('category')})")
                print(json.dumps(node, indent=2, ensure_ascii=False)[:500])
                break
        except:
            pass
