#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
verifier_tokens_sd.py
Vérifie qu'aucun token Hades II original ne reste dans les fiches Space Dracula.
"""

import json
from pathlib import Path

FICHES_DIR = Path(__file__).parent.parent / "space_dracula" / "fiches"

# Tokens Hades II à chercher
TOKENS_ORIGINAUX = [
    # Ennemis
    "Wastrel", "Whisper", "Casket", "Spindle", "Wailer", "ThornWeeper", "Wisp",
    "Pinhead", "Lurker", "Fishman", "Bone-Raker", "Bloodless", "Burn-Flinger",
    "Slam-Dancer", "Wave-Maker", "Smacker", "Bronzebeak",
    "Charybdis", "Wretched Thug", "Sky-Dracon", "Boozer", "Auto-Watcher",
    "Auto-Forcer", "Inferno-Bomber", "AutomatonBeamer", "AutomatonEnforcer",
    
    # Boss
    "Hecate", "Scylla", "Infernal Beast", "Chronos", "Polyphemus", "Eris", "Prometheus",
    
    # PNJ / Dieux
    "Arachne", "Aphrodite", "Apollo", "Ares", "Artemis", "Athena",
    "Demeter", "Hades", "Hermes", "Hephaestus", "Hypnos", "Nike",
    "Persephone", "Poseidon", "Zeus",
    
    # Niveaux
    "BiomeB", "BiomeF", "BiomeG", "BiomeH", "BiomeI", "BiomeN", "BiomeO", "BiomeP",
    
    # Armes
    "WeaponAxe", "WeaponBlink", "WeaponCast", "WeaponDagger", "WeaponLob",
    "WeaponMorphed", "WeaponSkullImpulse", "WeaponSpell", "WeaponSprint",
    "WeaponStaff", "WeaponSuit", "WeaponTorch", "WeaponTransform",
    "EncounterStartBuffWeapon", "Flashback", "PoseidonSprintWeapon", "SelfSlow",
    
    # Projectiles
    "ProjectileStaff", "ProjectileTorch", "ProjectileAxe", "ProjectileDagger",
    "ProjectileLob", "ProjectileMorphed", "ProjectileSkullImpulse", "ProjectileSpell",
    "ProjectileTransform",
    
    # IDs originaux
    "enemi-", "boss-", "miniboss-", "pnj-", "dieu-", "lvl_",
    
    # Props originaux (format AI.xxx avec point)
    "AI.PreAttackDuration", "AI.FireDuration", "AI.PostAttackDuration",
    "AI.AttackDistance", "AI.FireTicks", "AI.FireInterval", "AI.Spread",
    "AI.BarrelLength", "AI.NumProjectiles", "AI.ProjectileAngleInterval",
    "AI.SpawnRate", "AI.SpawnRadius", "AI.MaxActiveSpawns",
    
    # Props originaux (format CSV avec underscore)
    "AI_PreAttackDuration", "AI_FireDuration", "AI_PostAttackDuration",
    "AI_AttackDistance", "AI_FireTicks", "AI_FireInterval", "AI_Spread",
    "AI_BarrelLength", "AI_NumProjectiles", "AI_ProjectileAngleInterval",
    "AI_SpawnRate", "AI_SpawnRadius", "AI_MaxActiveSpawns",
    
    # Props originaux simples
    "MaxHealth", "HealthBuffer",
    "Gen_DifficultyRating",
    
    # Chaînes d'armes
    "SwapOnFire", "AddOnFire", "AddControlOnFire",
    "RemoveControlOnCharge", "ForceReleaseWeaponOnFire",
    
    # Tags UE5
    "Enemy.Lvl", "Boss.Lvl", "Attack.B", "Attack.E", "Level.Lvl",
    
    # Mini-boss
    "CrawlerMiniboss", "Dragon_MiniBoss", "GoldElemental_MiniBoss",
    "Lamia_Miniboss", "SatyrRatCatcher_Miniboss", "WaterUnitMiniboss",
    
    # Types de transition originaux
    "HealthThreshold", "SpawnedEncounterCleared",
]


def verifier_fichier(chemin: Path) -> list:
    """Vérifie un fichier JSON et retourne les tokens trouvés."""
    tokens_trouves = []
    try:
        content = chemin.read_text(encoding="utf-8")
        for token in TOKENS_ORIGINAUX:
            if token in content:
                count = content.count(token)
                tokens_trouves.append((token, count))
    except Exception as e:
        print(f"  Erreur sur {chemin.name}: {e}")
    return tokens_trouves


def main():
    print("Vérification des tokens Hades II dans les fiches Space Dracula...\n")
    
    fichiers = list(FICHES_DIR.glob("*_V2.json"))
    
    total_trouves = 0
    for fichier in sorted(fichiers):
        tokens = verifier_fichier(fichier)
        if tokens:
            print(f"  {fichier.name}: {len(tokens)} tokens originaux trouvés")
            for token, count in sorted(tokens, key=lambda x: -x[1]):
                print(f"    - {token} ({count}x)")
            total_trouves += len(tokens)
    
    if total_trouves == 0:
        print("AUCUN token Hades II original trouvé. Toutes les fiches v2 sont propres.")
    else:
        print(f"\n{total_trouves} tokens originaux restants à corriger.")


if __name__ == "__main__":
    main()
