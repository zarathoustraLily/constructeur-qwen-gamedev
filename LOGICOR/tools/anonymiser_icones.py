#!/usr/bin/env python3
"""Anonymiser ICONES_UI.json — remplacer les tokens originaux par des codes neutres."""
import json

CHIFFREMENTS = {
    "Hades_Symbol_01": "Symbole_01",
    "MelArmLeft": "BrasGauche",
    "MelArmRight": "BrasDroite",
    "PlantFNightshadeSeed": "PlanteToxique",
}

def main():
    path = r"D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE\fiches\ICONES_UI.json"
    with open(path, "r", encoding="utf-8") as f:
        icons = json.load(f)
    
    count = 0
    for ic in icons:
        original = ic["chemin"]
        for old, new in CHIFFREMENTS.items():
            if old in ic["chemin"]:
                ic["chemin"] = ic["chemin"].replace(old, new)
                count += 1
        # Also clean the nom
        for old, new in CHIFFREMENTS.items():
            if old in ic["nom"]:
                ic["nom"] = ic["nom"].replace(old, new)
    
    with open(path, "w", encoding="utf-8") as f:
        json.dump(icons, f, indent=2, ensure_ascii=False)
    
    print("Anonymisees: %d icones" % count)
    print("Total: %d icones" % len(icons))
    
    # Verify no original tokens remain
    tokens = ["Hades", "hades", "Mel", "Nem", "Herc", "Lato", "P22Underground"]
    remaining = 0
    for ic in icons:
        for t in tokens:
            if t.lower() in ic["nom"].lower() or t.lower() in ic["chemin"].lower():
                remaining += 1
                print("  RESTE: %s -> %s" % (ic["nom"], ic["chemin"]))
                break
    print("Tokens originaux restants: %d" % remaining)

if __name__ == "__main__":
    main()
