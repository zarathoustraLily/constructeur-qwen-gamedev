"""
anonymiser_mapping.py
Remplace tous les noms originaux par des codes neutres.
Le mapping devient : CODE -> { categorie, nom_affiche }
Aucun nom original n'apparait dans le fichier.
"""

import json
import os
import re

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPPING_PATH = os.path.join(BASE, "space_dracula", "donnees", "MAPPING_SPACE_DRACULA.json")

# Pattern pour les cles deja en code
PATTERN_CODE = re.compile(r'^(CRT|ANO|MIN|REL|SEC|NVA|COP|ENT|PAR|DIEU|PNJ)-\d+')

# Tokens a remplacer dans les cles
TOKENS_CLES = {
    "CRT.": "CRT-",
    "ANO.": "ANO-",
    "MIN.": "MIN-",
    "REL.": "REL-",
    "SEC.": "SEC-",
    "NVA.": "NVA-",
    "COP.": "COP-",
    "ENT.": "ENT-",
    "PAR.": "PAR-",
    "DIEU.": "DIEU-",
    "PNJ.": "PNJ-",
}


def nettoyer_cle(cle: str, index: int) -> str:
    """Nettoyer une cle en la convertissant en code propre."""
    # Si c'est deja un code, on le garde
    if PATTERN_CODE.match(cle):
        return cle

    # Remplacer les prefixes UE5
    for prefix, remplace in TOKENS_CLES.items():
        if cle.startswith(prefix):
            # CRT.DragonCeleste -> CRT-xxx
            return f"{remplace}{index:03d}"

    # Sinon, generer un code generique
    return f"ENT-{index:03d}"


def main():
    with open(MAPPING_PATH, "r", encoding="utf-8") as f:
        mapping = json.load(f)

    # Trier par categorie puis par nom pour avoir un ordre stable
    entries = sorted(mapping.items(), key=lambda x: (x[1]["categorie"], x[0]))

    # Compter par categorie pour generer les codes
    compteurs = {}
    nouveau_mapping = {}

    for cle_original, valeur in entries:
        cat = valeur["categorie"]
        if cat not in compteurs:
            compteurs[cat] = 0
        compteurs[cat] += 1
        index = compteurs[cat]

        # Generer le nom affiche
        noms_affiches = {
            "dieu": f"Dieu {index}",
            "pnj": f"PNJ {index}",
            "ennemi": f"Ennemi {index}",
            "niveau": f"Secteur {index}",
            "compagnon": f"Compagnon {index}",
            "mini-boss": f"Mini-boss {index}",
            "boss": f"Boss {index}",
            "arme": f"Relique {index}",
            "paramètre": f"Paramètre {index}",
            "entité": f"Entité {index}",
        }
        nom_affiche = noms_affiches.get(cat, f"Entité {index}")

        # Nettoyer la cle
        cle_nouvelle = nettoyer_cle(cle_original, index)

        # Eviter les doublons
        while cle_nouvelle in nouveau_mapping:
            index += 1
            cle_nouvelle = nettoyer_cle(cle_original, index)

        nouveau_mapping[cle_nouvelle] = {
            "categorie": cat,
            "nom_affiche": nom_affiche,
        }

    # Sauvegarder
    with open(MAPPING_PATH, "w", encoding="utf-8") as f:
        json.dump(nouveau_mapping, f, indent=2, ensure_ascii=False)

    print(f"Mapping anonymise: {len(nouveau_mapping)} entrees")
    print("Compteurs:", compteurs)

    # Verifier qu'il ne reste aucun nom original
    tokens_interdits = [
        "Aphrodite", "Apollo", "Arachne", "Ares", "Artemis", "Athena",
        "AutomatonBeamer", "AutomatonEnforcer", "BiomeB", "BiomeF",
        "BiomeG", "BiomeH", "BiomeI", "BloodlessBerserker", "BloodlessGrenadier",
        "BloodlessNaked", "BloodlessPitcher", "BloodlessSelfDestruct", "BloodlessWaveFist",
        "BrokenHearted", "Carrion", "CharybdisTentacle", "Chronos", "ClockworkHeavyMelee",
        "Cerberus", "Demeter", "Dionysus", "Dragon", "Drunk", "Eagle",
        "Elysium", "Erebus", "Asphodel", "Tartarus", "Olympus",
        "FishSwarmerSquad", "FishmanMelee", "FishmanRanged", "FogEmitter2",
        "GoldElemental", "Guard", "Guard2", "HarpyCutter", "HarpyDropper",
        "Hermes", "Lamia", "Lovesick", "Lycanthrope", "Mage", "Mage2",
        "Melinoe", "Mourner", "Mudman", "Nyx", "Poseidon", "Radiator",
        "Radiator2", "SatyrCrossbow2", "SatyrCultist", "SatyrLancer", "SatyrLancer2",
        "SatyrRatCatcher", "SatyrSapper", "Scimiterror", "Screamer", "SentryBot",
        "SiegeVine", "SirenDrummer", "SirenKeytarist", "SpreadShotUnit",
        "Stickler", "Swab", "Swarmer", "SwarmerClockwork", "Thanatos",
        "TimeElemental", "Turtle", "WaterElemental", "WaterUnit", "Wisp",
        "Zagreus", "Zombie", "ZombieAssassin", "ZombieHeavyRanged",
        "ZombieOlympus", "ZombieSpawner",
        "Brawler", "Hades",
        "DragonCeleste", "BeteInfernale", "BecBronze", "BombardierInfernal",
        "DanseurFrappe", "FabriqueVagues", "ForcerAuto", "Fouetteur",
        "GardienAuto", "Gredin", "Ivrogne", "LanceurBrûlure",
        "RacleurOsseux", "SansSang", "SorcierElite",
    ]

    contenu = json.dumps(nouveau_mapping, ensure_ascii=False)
    trouves = []
    for t in tokens_interdits:
        if t in contenu:
            trouves.append(t)

    if trouves:
        print(f"\nATTENTION: {len(trouves)} tokens restants: {trouves}")
    else:
        print("\nOK: aucun token original dans le mapping")


if __name__ == "__main__":
    main()
