#!/usr/bin/env python3
"""Generer FICHES_SALLES_V2.json depuis EncounterProfiles.json + SpawnPools_Lvl*.json

Format : une fiche par niveau (8 fiches), clés françaises.
Chaque fiche contient :
  - id, nom, niveau
  - profil : les params du profil de rencontre (clé françaises)
  - pool : la liste des ennemis avec poids et elite (clé françaises)
  - total_poids : somme des poids du pool
  - nb_types : nombre de types d'ennemis distincts

Sortie : A_TRADUIRE/fiches/FICHES_SALLES_V2.json
"""
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

A_TRADUIRE = r"D:\constructeur-qwen-gamedev\LOGICOR\A_TRADUIRE"

# Clé françaises pour les params de profil
MAPPING_CLES_PROFIL = {
    "BaseDifficulty": "DifficulteDeBase",
    "DepthDifficultyRamp": "RampDifficulteParProfondeur",
    "ActiveEnemyCapBase": "PlafondEnnemisDeBase",
    "ActiveEnemyCapDepthRamp": "RampPlafondParProfondeur",
    "ActiveEnemyCapMax": "PlafondEnnemisMax",
    "MinTypes": "TypesMin",
    "MaxTypes": "TypesMax",
    "MaxTypesCap": "PlafondTypes",
    "TypeCountDepthRamp": "RampTypesParProfondeur",
    "MaxEliteTypes": "EliteTypesMax",
    "MinWaves": "VaguesMin",
    "MaxWaves": "VaguesMax",
    "SpawnIntervalMin": "IntervalleSpawnMin",
    "SpawnIntervalMax": "IntervalleSpawnMax",
}

def charger_profil():
    path = os.path.join(A_TRADUIRE, "donnees", "EncounterProfiles.json")
    with open(path, encoding='utf-8') as f:
        d = json.load(f)
    return d

def charger_pool(niveau):
    path = os.path.join(A_TRADUIRE, "donnees", f"SpawnPools_Lvl{niveau:02d}.json")
    with open(path, encoding='utf-8') as f:
        d = json.load(f)
    return d

def traduire_cles(d, mapping):
    result = {}
    for k, v in d.items():
        nouveau = mapping.get(k, k)
        # Renommer GeneratedX en Profil_X
        if nouveau.startswith("Generated"):
            nouveau = "Profil_" + nouveau[len("Generated"):]
        result[nouveau] = v
    return result

def main():
    profil = charger_profil()
    profils = profil["Profiles"]
    level_profile = profil["LevelProfile"]
    
    salles = []
    
    for niveau in range(1, 9):
        cle_niveau = f"lvl_{niveau}"
        nom_profil = level_profile.get(cle_niveau)
        
        # Charger le pool
        pool_raw = charger_pool(niveau)
        entrees = []
        total_poids = 0
        types = set()
        
        for e in pool_raw["Entries"]:
            entrees.append({
                "ref": e["Ref"],
                "poids": e["Weight"],
                "elite": e["Elite"],
            })
            total_poids += e["Weight"]
            types.add(e["Ref"])
        
        # Charger le profil
        # Renommer GeneratedX en Profil_X
        profil_nom_affiche = "aucun"
        if nom_profil:
            if nom_profil.startswith("Generated"):
                profil_nom_affiche = "Profil_" + nom_profil[len("Generated"):]
            else:
                profil_nom_affiche = nom_profil
        
        fiche = {
            "id": f"SLA-{niveau:02d}",
            "nom": f"Niveau {niveau}",
            "niveau": niveau,
            "profil_nom": profil_nom_affiche,
        }
        
        if nom_profil and nom_profil in profils:
            p = profils[nom_profil]
            fiche["profil"] = traduire_cles(p, MAPPING_CLES_PROFIL)
        else:
            # lvl_8 a aucun profil — on utilise les valeurs par defaut
            fiche["profil"] = {
                "DifficulteDeBase": 30,
                "RampDifficulteParProfondeur": 10,
                "PlafondEnnemisDeBase": 2.3,
                "RampPlafondParProfondeur": 0.35,
                "PlafondEnnemisMax": 8,
                "TypesMin": 1,
                "TypesMax": 2,
                "PlafondTypes": 4,
                "RampTypesParProfondeur": 0.2,
                "VaguesMin": 1,
                "VaguesMax": 3,
                "IntervalleSpawnMin": 0.175,
                "IntervalleSpawnMax": 0.225,
            }
        
        fiche["pool"] = entrees
        fiche["total_poids"] = total_poids
        fiche["nb_types"] = len(types)
        
        salles.append(fiche)
    
    # Ecrire dans A_TRADUIRE
    out = os.path.join(A_TRADUIRE, "fiches", "FICHES_SALLES_V2.json")
    with open(out, 'w', encoding='utf-8') as f:
        json.dump(salles, f, ensure_ascii=False, indent=2)
    
    # Ecrire aussi dans space_dracula/fiches/ pour coherence
    out2 = r"D:\constructeur-qwen-gamedev\LOGICOR\space_dracula\fiches\FICHES_SALLES_V2.json"
    with open(out2, 'w', encoding='utf-8') as f:
        json.dump(salles, f, ensure_ascii=False, indent=2)
    
    print(f"FICHES_SALLES_V2.json : {len(salles)} fiches")
    for s in salles:
        print(f"  {s['id']} : {s['nom']} | profil={s['profil_nom']} | {s['nb_types']} types | poids total={s['total_poids']}")

if __name__ == '__main__':
    main()
