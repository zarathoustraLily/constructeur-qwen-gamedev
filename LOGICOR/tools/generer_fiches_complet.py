#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generer_fiches_complet.py
Génère les fiches Space Dracula complètes à partir de la carte UE5.
"""

import json
import csv
from pathlib import Path

CARTE_DIR = Path(r"F:\Hades II.wawacity.click\Hades II\Hades II\_GAME_MAP_v2 -generalise - convertie")
EXPORTS_DIR = CARTE_DIR / "Exports" / "UE5"
OUTPUT_DIR = Path(__file__).parent.parent / "space_dracula" / "fiches"
MAPPING_FILE = Path(__file__).parent.parent / "space_dracula" / "donnees" / "MAPPING_SPACE_DRACULA.json"


def charger_mapping() -> dict:
    """Charge le mapping de renommage."""
    with open(MAPPING_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def renomer_token(token: str, mapping: dict) -> str:
    """Renames a token using the mapping."""
    if token in mapping:
        return mapping[token]["nom_sd"]
    for original, info in mapping.items():
        if original in token and len(original) > 3:
            return token.replace(original, info["nom_sd"])
    return token


def charger_csv(fichier: str) -> list:
    """Charge un fichier CSV."""
    chemin = EXPORTS_DIR / fichier
    if not chemin.exists():
        return []
    with open(chemin, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        return list(reader)


def charger_json(fichier: str) -> dict:
    """Charge un fichier JSON."""
    chemin = EXPORTS_DIR / fichier
    if not chemin.exists():
        return {}
    with open(chemin, "r", encoding="utf-8") as f:
        return json.load(f)


def generer_fiche_boss_b001(mapping: dict) -> dict:
    """Génère la fiche du boss B001 (Hecate -> ANO-001)."""
    # Charger les données
    boss_registry = charger_csv("DT_BossRegistry.csv")
    attack_registry = charger_csv("DT_AttackRegistry.csv")
    boss_phases = charger_json("BossPhases_B001.json")
    
    # Trouver le boss
    boss_data = None
    for row in boss_registry:
        if "B001" in row.get("Tag", ""):
            boss_data = row
            break
    
    if not boss_data:
        return {}
    
    # Extraire les attaques
    attaques = []
    for row in attack_registry:
        if "B001" in row.get("OwnerTag", ""):
            attaque = {
                "id": renomer_token(row.get("RowName", ""), mapping).replace("Attack.", "ANO-001_"),
                "props": {}
            }
            # Extraire les props
            for key, value in row.items():
                if value and key != "RowName" and key != "OwnerTag" and key != "DisplayName":
                    new_key = renomer_token(key, mapping)
                    try:
                        if "." in value:
                            attaque["props"][new_key] = float(value)
                        else:
                            attaque["props"][new_key] = int(value)
                    except ValueError:
                        attaque["props"][new_key] = value
            attaques.append(attaque)
    
    # Extraire les phases
    phases = []
    for phase in boss_phases.get("Phases", []):
        phases.append({
            "id": f"ANO-001_Phase{phase.get('StageIndex', 1)}",
            "props": {
                "TypeTransition": phase.get("TransitionType"),
                "Seuil": phase.get("Threshold"),
                "NouveauPVMax": phase.get("NewMaxHealth"),
                "AttenteDuree": phase.get("WaitDuration"),
                "DequiperToutesArmes": phase.get("UnequipAll"),
                "ArmesEquipees": [renomer_token(w.get("Tag", ""), mapping) for w in phase.get("EquipWeapons", [])],
            }
        })
    
    return {
        "id": "ANO-001",
        "nom": "ANO-001",
        "categorie": "boss",
        "props": {
            "PV_Max": int(boss_data.get("MaxHealth", 0)),
            "Vitesse": int(boss_data.get("Speed", 0)),
            "NoteDifficulte": int(boss_data.get("Gen_DifficultyRating", 0) or 0),
            "PorteeAggro": float(boss_data.get("AIAggroRange", 0) or 0),
            "TamponPV": int(boss_data.get("HealthBuffer", 0) or 0),
            "DelaiEveil": float(boss_data.get("AIWakeDelay", 0) or 0),
            "DelaiSetupIA": float(boss_data.get("AISetupDelay", 0) or 0),
            "MaxAttaquants": int(boss_data.get("AI_MaxAttackers", 0) or 0),
            "DistanceEntourer": float(boss_data.get("AI_SurroundDistance", 0) or 0),
            "IntervalleRafraichissement": float(boss_data.get("AI_SurroundRefreshInterval", 0) or 0),
            "SeuilPVFin": float(boss_data.get("AIEndHealthThreshold", 0) or 0),
        },
        "phases": phases,
        "attaques": attaques,
        "arsenal": [renomer_token(a, mapping) for a in boss_data.get("ArsenalTags", "").split("|") if a],
    }


def main():
    print("Chargement du mapping...")
    mapping = charger_mapping()
    
    print("Génération des fiches bosses complètes...")
    
    # Générer les fiches des 7 bosses
    bosses_fiches = []
    for i in range(1, 8):
        boss_id = f"B00{i}"
        print(f"  - Boss {boss_id}...")
        
        # Charger les données
        boss_registry = charger_csv("DT_BossRegistry.csv")
        attack_registry = charger_csv("DT_AttackRegistry.csv")
        boss_phases = charger_json(f"BossPhases_{boss_id}.json")
        
        # Trouver le boss
        boss_data = None
        for row in boss_registry:
            if boss_id in row.get("Tag", ""):
                boss_data = row
                break
        
        if not boss_data:
            continue
        
        # Extraire les attaques
        attaques = []
        for row in attack_registry:
            if boss_id in row.get("OwnerTag", ""):
                # Nettoyer l'ID de l'attaque
                row_name = row.get("RowName", "")
                # Ex: Attack.B001.Melee1 -> ANO-001_Melee1
                nom_attaque = row_name.replace(f"Attack.{boss_id}.", f"ANO-00{i}_")
                
                attaque = {
                    "id": nom_attaque,
                    "props": {}
                }
                # Extraire les props
                for key, value in row.items():
                    if value and key not in ("RowName", "OwnerTag", "DisplayName"):
                        new_key = renomer_token(key, mapping)
                        try:
                            if "." in value:
                                attaque["props"][new_key] = float(value)
                            else:
                                attaque["props"][new_key] = int(value)
                        except ValueError:
                            attaque["props"][new_key] = value
                attaques.append(attaque)
        
        # Extraire les phases
        phases = []
        for phase in boss_phases.get("Phases", []):
            phases.append({
                "id": f"ANO-00{i}_Phase{phase.get('StageIndex', 1)}",
                "props": {
                    "TypeTransition": phase.get("TransitionType"),
                    "Seuil": phase.get("Threshold"),
                    "NouveauPVMax": phase.get("NewMaxHealth"),
                    "AttenteDuree": phase.get("WaitDuration"),
                    "DequiperToutesArmes": phase.get("UnequipAll"),
                    "ArmesEquipees": [w.get("Tag", "").replace(f"Attack.{boss_id}.", f"ANO-00{i}_") for w in phase.get("EquipWeapons", [])],
                }
            })
        
        fiche = {
            "id": f"ANO-00{i}",
            "nom": f"ANO-00{i}",
            "categorie": "boss",
            "props": {
                "PV_Max": int(boss_data.get("MaxHealth", 0) or 0),
                "Vitesse": int(boss_data.get("Speed", 0) or 0),
                "NoteDifficulte": int(boss_data.get("Gen_DifficultyRating", 0) or 0),
                "PorteeAggro": float(boss_data.get("AIAggroRange", 0) or 0),
                "TamponPV": int(boss_data.get("HealthBuffer", 0) or 0),
                "DelaiEveil": float(boss_data.get("AIWakeDelay", 0) or 0),
                "DelaiSetupIA": float(boss_data.get("AISetupDelay", 0) or 0),
                "MaxAttaquants": int(boss_data.get("AI_MaxAttackers", 0) or 0),
                "DistanceEntourer": float(boss_data.get("AI_SurroundDistance", 0) or 0),
                "IntervalleRafraichissement": float(boss_data.get("AI_SurroundRefreshInterval", 0) or 0),
                "SeuilPVFin": float(boss_data.get("AIEndHealthThreshold", 0) or 0),
            },
            "phases": phases,
            "attaques": attaques,
            "arsenal": [a.replace(f"Attack.{boss_id}.", f"ANO-00{i}_") for a in boss_data.get("ArsenalTags", "").split("|") if a],
        }
        bosses_fiches.append(fiche)
    
    # Écrire les fiches
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_DIR / "FICHES_BOSSES_COMPLET.json", "w", encoding="utf-8") as f:
        json.dump(bosses_fiches, f, indent=2, ensure_ascii=False)
    
    print(f"\n=== FICHES BOSSES COMPLÈTES GÉNÉRÉES ===")
    print(f"  Bosses: {len(bosses_fiches)}")
    for fiche in bosses_fiches:
        print(f"  {fiche['id']}: {len(fiche['phases'])} phases, {len(fiche['attaques'])} attaques")
    
    print(f"\nÉcrit dans: {OUTPUT_DIR / 'FICHES_BOSSES_COMPLET.json'}")


if __name__ == "__main__":
    main()
