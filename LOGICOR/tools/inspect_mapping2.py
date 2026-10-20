#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
from pathlib import Path

f = Path("space_dracula/donnees/MAPPING_RENOMMAGE.json")
m = json.load(open(f, encoding="utf-8"))

# Chercher les ennemis (categorie ennemi)
ennemis = {k: v for k, v in m.items() if v.get("categorie") == "ennemi"}
print(f"Ennemis: {len(ennemis)}")
print("Premiers 5:", json.dumps(list(ennemis.items())[:5], indent=2, ensure_ascii=False))

# Chercher Wastrel, Whisper, Casket
for token in ["Wastrel", "Whisper", "Casket", "Spindle", "Wailer"]:
    if token in m:
        print(f"  {token}: {m[token]}")
    else:
        print(f"  {token}: PAS TROUVÉ")
