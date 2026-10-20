#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
from pathlib import Path

fiches_dir = Path(__file__).parent.parent / "space_dracula" / "fiches"

# Ennemis
with open(fiches_dir / "FICHES_ENNEMIS.json", "r", encoding="utf-8") as f:
    ennemis = json.load(f)
total_props = sum(len(e['props']) for e in ennemis)
avec_props = sum(1 for e in ennemis if e['props'])
print(f"ENNEMIS: {avec_props}/{len(ennemis)} avec props, {total_props} props totaux")

# Bosses
with open(fiches_dir / "FICHES_BOSSES.json", "r", encoding="utf-8") as f:
    bosses = json.load(f)
total_props = sum(len(b['props']) for b in bosses)
total_phases = sum(len(b['phases']) for b in bosses)
total_attaques = sum(len(b['attaques']) for b in bosses)
print(f"BOSSES: {len(bosses)} boss, {total_props} props, {total_phases} phases, {total_attaques} attaques")

# Mini-bosses
with open(fiches_dir / "FICHES_MINI_BOSSES.json", "r", encoding="utf-8") as f:
    minis = json.load(f)
total_props = sum(len(b['props']) for b in minis)
total_phases = sum(len(b['phases']) for b in minis)
total_attaques = sum(len(b['attaques']) for b in minis)
print(f"MINI-BOSSES: {len(minis)} mini-boss, {total_props} props, {total_phases} phases, {total_attaques} attaques")

# Armes
with open(fiches_dir / "FICHES_ARMES.json", "r", encoding="utf-8") as f:
    armes = json.load(f)
total_props = sum(len(a['props']) for a in armes)
total_chaines = sum(len(a['chaines']) for a in armes)
print(f"ARMES: {len(armes)} armes, {total_props} props, {total_chaines} chaines")
