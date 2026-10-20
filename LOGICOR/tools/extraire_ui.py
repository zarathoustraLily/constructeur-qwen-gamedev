#!/usr/bin/env python3
"""Extraire les données UI de UIData.lua et HUDData.lua pour Space Dracula."""
import re
import json

LUA_DIR = r"E:\TRAVAIL\jeu_HADES_3\analyse du jeu hades 2\analyse par qwen\Content\Scripts"

# === 1. TextFormats ===
def extraire_textformats():
    with open(f"{LUA_DIR}/UIData.lua", "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()
    
    formats = []
    current = None
    in_formats = False
    for i in range(53, 723):
        line = lines[i].rstrip()
        stripped = line.strip()
        if stripped == "TextFormats =":
            in_formats = True
            continue
        if not in_formats:
            continue
        if re.match(r'^[A-Z][a-zA-Z]*Format\w*\s*=', stripped):
            name = re.match(r'^([A-Z][a-zA-Z]*Format\w*)', stripped).group(1)
            current = {"nom": name, "props": {}}
            formats.append(current)
            continue
        if current and stripped and not stripped.startswith("--") and not stripped in ["{", "}", "},", "},"]:
            if "=" in stripped:
                key, _, val = stripped.partition("=")
                key = key.strip().rstrip(",")
                val = val.strip().rstrip(",")
                # Clean value
                val = val.strip('"')
                if val.startswith("{") and val.endswith("}"):
                    val = val  # keep as string, will parse later
                current["props"][key] = val
    
    return formats

# === 2. IconData ===
def extraire_icondata():
    with open(f"{LUA_DIR}/UIData.lua", "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()
    
    icons = []
    current = None
    in_icons = False
    for i in range(723, 1814):
        line = lines[i].rstrip()
        stripped = line.strip()
        if stripped == "IconData =":
            in_icons = True
            continue
        if not in_icons:
            continue
        if re.match(r'^[A-Z][a-zA-Z_]*\s*=\s*$', stripped) or re.match(r'^[A-Z][a-zA-Z_]*\s*=\s*\{', stripped):
            name = re.match(r'^([A-Z][a-zA-Z_]*)', stripped).group(1)
            current = {"nom": name, "chemin": ""}
            icons.append(current)
            continue
        if current and "TexturePath" in stripped:
            m = re.search(r'TexturePath\s*=\s*"([^"]+)"', stripped)
            if m:
                current["chemin"] = m.group(1)
    
    return icons

# === 3. CombatUI ===
def extraire_combatui():
    with open(f"{LUA_DIR}/UIData.lua", "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()
    
    data = {}
    in_combat = False
    for i in range(1853, 1899):
        line = lines[i].rstrip()
        stripped = line.strip()
        if stripped == "CombatUI =":
            in_combat = True
            continue
        if not in_combat:
            continue
        if "=" in stripped and not stripped.startswith("--"):
            key, _, val = stripped.partition("=")
            key = key.strip().rstrip(",")
            val = val.strip().rstrip(",")
            if key and val:
                data[key] = val
    
    return data

# === 4. HUDData components ===
def extraire_huddata():
    with open(f"{LUA_DIR}/HUDData.lua", "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()
    
    components = []
    current = None
    in_components = False
    for line in lines:
        stripped = line.strip()
        if stripped == "ComponentData =":
            in_components = True
            continue
        if not in_components:
            continue
        if re.match(r'^[A-Z][a-zA-Z]*\s*=\s*$', stripped) or re.match(r'^[A-Z][a-zA-Z]*\s*=\s*\{', stripped):
            name = re.match(r'^([A-Z][a-zA-Z]*)', stripped).group(1)
            if name in ["Order", "DefaultGroup"]:
                current = None
                continue
            current = {"nom": name, "props": {}}
            components.append(current)
            continue
        if current and stripped and not stripped.startswith("--"):
            if "=" in stripped:
                key, _, val = stripped.partition("=")
                key = key.strip().rstrip(",")
                val = val.strip().rstrip(",")
                val = val.strip('"')
                if key and val and key != "TextArgs":
                    current["props"][key] = val
    
    return components

# === 5. ScreenData.HUD ===
def extraire_screen_data():
    with open(f"{LUA_DIR}/HUDData.lua", "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()
    
    data = {}
    in_screen = False
    for line in lines:
        stripped = line.strip()
        if "ScreenData.HUD" in stripped:
            in_screen = True
            continue
        if not in_screen:
            continue
        if "=" in stripped and not stripped.startswith("--") and not stripped.startswith("{"):
            key, _, val = stripped.partition("=")
            key = key.strip().rstrip(",")
            val = val.strip().rstrip(",")
            val = val.strip('"')
            if key and val and not key.startswith("ComponentData") and not key.startswith("GroupOrder") and not key.startswith("SlottedTraitOrder") and not key.startswith("ActiveTraitOrder"):
                data[key] = val
    
    return data

def main():
    print("=== EXTRACTION UI ===\n")
    
    formats = extraire_textformats()
    print(f"TextFormats: {len(formats)}")
    
    icons = extraire_icondata()
    print(f"IconData: {len(icons)}")
    
    combat = extraire_combatui()
    print(f"CombatUI: {len(combat)} props")
    
    components = extraire_huddata()
    print(f"HUD Components: {len(components)}")
    
    screen = extraire_screen_data()
    print(f"ScreenData.HUD: {len(screen)} props")
    
    # Build the JSON
    result = {
        "text_formats": formats,
        "icones": icons,
        "combat_ui": combat,
        "hud_components": components,
        "screen_data": screen,
    }
    
    out_path = r"D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE\fiches\DONNEES_UI.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    
    print(f"\nSauvegardé: {out_path}")

if __name__ == "__main__":
    main()
