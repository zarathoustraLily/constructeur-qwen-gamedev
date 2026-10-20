#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
from pathlib import Path

f = Path("space_dracula/fiches/FICHES_ENNEMIS_V2.json")
d = json.load(open(f, encoding="utf-8"))
props_tous = set()
for e in d:
    props_tous.update(e['props'].keys())
print(f"Ennemis: {len(d)}")
print(f"Props uniques: {len(props_tous)}")
for k in sorted(props_tous):
    print(f"  {k}")
