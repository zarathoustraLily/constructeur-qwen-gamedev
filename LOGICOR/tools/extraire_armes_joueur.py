#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
extraire_armes_joueur.py
Extrait les armes du joueur depuis les fichiers SJSON.
"""

import json
import re
from pathlib import Path

CARTE_DIR = Path(r"F:\Hades II.wawacity.click\Hades II\Hades II\_GAME_MAP_v2 -generalise - convertie")
EXPORTS_DIR = CARTE_DIR / "Exports"
OUTPUT_DIR = Path(__file__).parent.parent / "space_dracula" / "donnees"


def parser_sjson_simple(content: str) -> list:
    """Parse simple d'un fichier SJSON."""
    # Trouver tous les blocs { ... }
    records = []
    depth = 0
    start = -1
    
    for i, c in enumerate(content):
        if c == '{':
            if depth == 0:
                start = i
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0 and start >= 0:
                block = content[start:i+1]
                records.append(block)
                start = -1
    
    return records


def extraire_nom(block: str) -> str:
    """Extrait le nom d'un record SJSON."""
    match = re.search(r'Name\s*=\s*"([^"]+)"', block)
    if match:
        return match.group(1)
    return ""


def extraire_props(block: str) -> dict:
    """Extrait les props d'un record SJSON."""
    props = {}
    # Trouver Name = "value"
    match = re.search(r'Name\s*=\s*"([^"]+)"', block)
    if match:
        props['Name'] = match.group(1)
    
    # Trouver InheritFrom = "value"
    match = re.search(r'InheritFrom\s*=\s*"([^"]+)"', block)
    if match:
        props['InheritFrom'] = match.group(1)
    
    # Trouver SwapOnFire = "value"
    match = re.search(r'SwapOnFire\s*=\s*"([^"]+)"', block)
    if match:
        props['SwapOnFire'] = match.group(1)
    
    # Trouver AddOnFire = "value"
    match = re.search(r'AddOnFire\s*=\s*"([^"]+)"', block)
    if match:
        props['AddOnFire'] = match.group(1)
    
    # Trouver AddControlOnFire = "value"
    match = re.search(r'AddControlOnFire\s*=\s*"([^"]+)"', block)
    if match:
        props['AddControlOnFire'] = match.group(1)
    
    # Trouver RemoveControlOnCharge = "value"
    match = re.search(r'RemoveControlOnCharge\s*=\s*"([^"]+)"', block)
    if match:
        props['RemoveControlOnCharge'] = match.group(1)
    
    # Trouver ForceReleaseWeaponOnFire = "value"
    match = re.search(r'ForceReleaseWeaponOnFire\s*=\s*"([^"]+)"', block)
    if match:
        props['ForceReleaseWeaponOnFire'] = match.group(1)
    
    # Trouver Projectile = "value"
    match = re.search(r'Projectile\s*=\s*"([^"]+)"', block)
    if match:
        props['Projectile'] = match.group(1)
    
    # Trouver ChargeTime = value
    match = re.search(r'ChargeTime\s*=\s*([\d.]+)', block)
    if match:
        props['ChargeTime'] = float(match.group(1))
    
    return props


def main():
    print("Chargement des armes du joueur depuis les fichiers SJSON...")
    
    # Trouver les fichiers d'armes
    weapon_files = []
    if EXPORTS_DIR.exists():
        for f in EXPORTS_DIR.rglob("*.sjson"):
            if "Weapon" in f.name or "weapon" in f.name.lower():
                weapon_files.append(f)
    
    print(f"  - Fichiers d'armes trouvés: {len(weapon_files)}")
    for f in weapon_files:
        print(f"    {f.name}")
    
    # Extraire les armes
    armes = {}
    for f in weapon_files:
        try:
            content = f.read_text(encoding='utf-8')
            blocks = parser_sjson_simple(content)
            for block in blocks:
                nom = extraire_nom(block)
                if nom:
                    props = extraire_props(block)
                    armes[nom] = props
        except Exception as e:
            print(f"  Erreur sur {f.name}: {e}")
    
    print(f"\n  - Armes extraites: {len(armes)}")
    
    # Afficher les armes avec chaînes
    print("\n=== ARMES AVEC CHAÎNES ===")
    for nom, props in armes.items():
        chaines = []
        if 'SwapOnFire' in props:
            chaines.append(f"Swap->{props['SwapOnFire']}")
        if 'AddOnFire' in props:
            chaines.append(f"Add->{props['AddOnFire']}")
        if 'AddControlOnFire' in props:
            chaines.append(f"AddCtrl->{props['AddControlOnFire']}")
        if chaines:
            print(f"  {nom}: {', '.join(chaines)}")
    
    # Écrire les données
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_DIR / "ARMES_JOUEUR.json", "w", encoding="utf-8") as f:
        json.dump(armes, f, indent=2, ensure_ascii=False)
    
    print(f"\nÉcrit dans: {OUTPUT_DIR / 'ARMES_JOUEUR.json'}")


if __name__ == "__main__":
    main()
