#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
from pathlib import Path

f = Path("space_dracula/donnees/MAPPING_RENOMMAGE.json")
m = json.load(open(f, encoding="utf-8"))
print("Type:", type(m))
if isinstance(m, list):
    print("Longueur:", len(m))
    print("Premiers:", json.dumps(m[:3], indent=2, ensure_ascii=False))
elif isinstance(m, dict):
    print("Clés:", list(m.keys())[:10])
    for k in list(m.keys())[:3]:
        print(f"  {k}: {m[k]}")
