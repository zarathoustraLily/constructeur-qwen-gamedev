#!/usr/bin/env python3
"""Extraire IconData de UIData.lua."""
import re
import json

LUA_DIR = r"E:\TRAVAIL\jeu_HADES_3\analyse du jeu hades 2\analyse par qwen\Content\Scripts"

def extraire_icondata():
    with open(LUA_DIR + "/UIData.lua", "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()
    
    icons = []
    current = None
    for i in range(723, 1814):
        line = lines[i].rstrip()
        # Icon name: tab + Name + space + = (exact)
        m = re.match(r'^\t([A-Z][a-zA-Z_]+) =$', line)
        if m:
            name = m.group(1)
            current = {"nom": name, "chemin": ""}
            icons.append(current)
            continue
        if current and "TexturePath" in line:
            m2 = re.search(r'TexturePath = "([^"]+)"', line)
            if m2:
                current["chemin"] = m2.group(1)
    
    return icons

def main():
    icons = extraire_icondata()
    print("IconData: %d icones" % len(icons))
    for ic in icons[:15]:
        print("  %s -> %s" % (ic["nom"], ic["chemin"][:50]))
    if len(icons) > 15:
        print("  ... (%d autres)" % (len(icons) - 15))
    
    out = r"D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE\fiches\ICONES_UI.json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump(icons, f, indent=2, ensure_ascii=False)
    print("Sauvegarde: %s" % out)

if __name__ == "__main__":
    main()
