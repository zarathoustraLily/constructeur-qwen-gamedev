#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
from pathlib import Path

f = Path("space_dracula/donnees/MAPPING_RENOMMAGE.json")
m = json.load(open(f, encoding="utf-8"))

# Chercher les ennemis avec lvl_1
ennemis_lvl1 = {k: v for k, v in m.items() if v.get("categorie") == "ennemi" and "lvl_1" in v.get("nom_space_dracula", "")}
print(f"Ennemis lvl_1: {len(ennemis_lvl1)}")
for k, v in sorted(ennemis_lvl1.items())[:10]:
    print(f"  {k}: {v['nom_space_dracula']}")

# Chercher Fishman
for k, v in m.items():
    if "Fishman" in k or "Fishman" in v.get("nom_space_dracula", ""):
        print(f"  Fishman trouvé: {k} -> {v}")
