#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
from pathlib import Path

CARTE_DIR = Path(r"F:\Hades II.wawacity.click\Hades II\Hades II\_GAME_MAP_v2 -generalise - convertie")
IDENTITY_MAP_FILE = CARTE_DIR / "identity_map.json"

identity_map = json.load(open(IDENTITY_MAP_FILE, encoding="utf-8"))
armes = {k: v for k, v in identity_map.items() if v.get("categorie") == "arme"}

print(f"Armes: {len(armes)}")
for k, v in list(armes.items())[:5]:
    print(f"\n{k}:")
    print(json.dumps(v, indent=2, ensure_ascii=False))
