#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
from pathlib import Path

CARTE_DIR = Path(r"F:\Hades II.wawacity.click\Hades II\Hades II\_GAME_MAP_v2 -generalise - convertie")
GRAPH_FILE = CARTE_DIR / "graph.jsonl"

# Lire les 10 premières lignes pour comprendre la structure
with open(GRAPH_FILE, "r", encoding="utf-8") as f:
    for i, line in enumerate(f):
        if i >= 10:
            break
        try:
            node = json.loads(line)
            print(f"Ligne {i+1}:")
            print(json.dumps(node, indent=2, ensure_ascii=False)[:500])
            print("---")
        except:
            print(f"Ligne {i+1}: ERREUR")
            print(line[:200])
            print("---")
