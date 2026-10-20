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

# Charger graph.jsonl et chercher les edges
edges = []
with open(GRAPH_FILE, "r", encoding="utf-8") as f:
    for line in f:
        try:
            node = json.loads(line)
            if node.get("type") == "edge":
                edges.append(node)
        except:
            pass

print(f"Edges: {len(edges)}")
print("Premier edge:", json.dumps(edges[0], indent=2, ensure_ascii=False) if edges else "AUCUN")

# Chercher les edges qui partent d'une arme
armes_ids = list(armes.keys())
edges_armes = []
for edge in edges:
    source = edge.get("source", "")
    if source in armes_ids:
        edges_armes.append(edge)

print(f"\nEdges depuis les armes: {len(edges_armes)}")
for edge in edges_armes[:5]:
    print(json.dumps(edge, indent=2, ensure_ascii=False))
