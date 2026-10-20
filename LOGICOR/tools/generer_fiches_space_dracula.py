#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generer_fiches_space_dracula.py
Génère les fiches de données Space Dracula à partir de la carte Hades II.
Tous les tokens Hades II sont renommés en tokens Space Dracula.
"""

import json
from pathlib import Path

CARTE_DIR = Path(r"F:\Hades II.wawacity.click\Hades II\Hades II\_GAME_MAP_v2 -generalise - convertie")
OUTPUT_DIR = Path(__file__).parent.parent / "space_dracula" / "fiches"
MAPPING_FILE = Path(__file__).parent.parent / "space_dracula" / "donnees" / "MAPPING_SPACE_DRACULA.json"


def charger_mapping() -> dict:
    """Charge le mapping de renommage."""
    with open(MAPPING_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def charger_mapping_complet(identity: dict, mapping: dict) -> dict:
    """Construit un mapping complet incluant les IDs nom_actuel."""
    mapping_complet = dict(mapping)
    for name, info in identity.items():
        nom_actuel = info.get("nom_actuel", name)
        nom_sd = mapping.get(name, {}).get("nom_sd", name)
        if nom_actuel not in mapping_complet:
            mapping_complet[nom_actuel] = {
                "nom_sd": nom_sd,
                "categorie": info.get("categorie", "inconnu"),
                "nom_affiche": info.get("nom_affiche_origine", name),
            }
    return mapping_complet


def charger_identity() -> dict:
    """Charge la carte d'identité."""
    with open(CARTE_DIR / "identity_map.json", "r", encoding="utf-8") as f:
        return json.load(f)


def charger_props() -> list:
    """Charge les propriétés."""
    with open(CARTE_DIR / "props.jsonl", "r", encoding="utf-8") as f:
        return [json.loads(line) for line in f if line.strip()]


def charger_graph() -> list:
    """Charge le graphe."""
    with open(CARTE_DIR / "graph.jsonl", "r", encoding="utf-8") as f:
        return [json.loads(line) for line in f if line.strip()]


def renomer_token(token: str, mapping: dict) -> str:
    """Renames a token using the mapping."""
    if token in mapping:
        return mapping[token]["nom_sd"]
    # Si le token contient un ID connu, renommer cette partie
    for original, info in mapping.items():
        if original in token and len(original) > 3:
            return token.replace(original, info["nom_sd"])
    return token


def renomer_props(props: dict, mapping: dict) -> dict:
    """Renames all keys in a props dict."""
    result = {}
    for key, value in props.items():
        new_key = renomer_token(key, mapping)
        if isinstance(value, dict):
            result[new_key] = renomer_props(value, mapping)
        elif isinstance(value, list):
            result[new_key] = [renomer_props(item, mapping) if isinstance(item, dict) else renomer_token(str(item), mapping) for item in value]
        else:
            result[new_key] = value
    return result


def generer_fiche_ennemi(ennemi_info: dict, props: list, mapping: dict) -> dict:
    """Génère une fiche d'ennemi Space Dracula."""
    nom_original = ennemi_info["nom_original"]
    nom_sd = ennemi_info["nom_sd"]
    
    # Trouver les props de cet ennemi
    ennemi_props = {}
    for p in props:
        id_ = p.get("id", "")
        if nom_original in id_ or ennemi_info["nom_actuel"] in id_:
            # Ajouter les props
            for key, value in p.get("props", {}).items():
                new_key = renomer_token(key, mapping)
                ennemi_props[new_key] = value
    
    return {
        "id": nom_sd,
        "nom": nom_sd,
        "categorie": "ennemi",
        "props": ennemi_props,
    }


def nettoyer_id_phase(id_: str, nom_sd_boss: str) -> str:
    """Nettoie un ID de phase pour le rendre propre Space Dracula."""
    import re
    # Extraire le numéro de stage
    match = re.search(r'Stage(\d+)', id_)
    if match:
        num = match.group(1)
        return f"{nom_sd_boss}_Phase{num}"
    return renomer_token(id_, {})


def nettoyer_id_attaque(id_: str, nom_sd_boss: str) -> str:
    """Nettoie un ID d'attaque pour le rendre propre Space Dracula."""
    import re
    # Extraire le nom de l'attaque (après le dernier _ ou -)
    # Ex: boss-004-lvl_4SwingRight -> SwingRight
    match = re.search(r'(?:boss-\d+-lvl_\d+|miniboss-\d+-lvl_\d+)(.+)', id_)
    if match:
        nom_attaque = match.group(1)
        return f"{nom_sd_boss}_{nom_attaque}"
    return renomer_token(id_, {})


def generer_fiche_boss(boss_info: dict, props: list, mapping: dict) -> dict:
    """Génère une fiche de boss Space Dracula."""
    nom_original = boss_info["nom_original"]
    nom_sd = boss_info["nom_sd"]
    
    # Trouver les props de ce boss
    boss_props = {}
    phases = []
    attaques = []
    
    for p in props:
        id_ = p.get("id", "")
        if nom_original in id_ or boss_info["nom_actuel"] in id_:
            props_dict = p.get("props", {})
            
            # Ajouter les props de base
            for key, value in props_dict.items():
                new_key = renomer_token(key, mapping)
                if new_key not in boss_props:
                    boss_props[new_key] = value
            
            # Vérifier si c'est une phase (Stage*)
            if "Stage" in id_:
                phase_data = {
                    "id": nettoyer_id_phase(id_, nom_sd),
                    "props": {renomer_token(k, mapping): v for k, v in props_dict.items()},
                }
                phases.append(phase_data)
            
            # Vérifier si c'est le boss de base (id_ == nom_actuel)
            elif id_ == boss_info["nom_actuel"]:
                pass  # Les props sont déjà dans boss_props
            
            # Vérifier si c'est une attaque (n'a pas de Stage)
            elif "Stage" not in id_ and props_dict:
                attaque_data = {
                    "id": nettoyer_id_attaque(id_, nom_sd),
                    "props": {renomer_token(k, mapping): v for k, v in props_dict.items()},
                }
                attaques.append(attaque_data)
    
    return {
        "id": nom_sd,
        "nom": nom_sd,
        "categorie": "boss",
        "props": boss_props,
        "phases": phases,
        "attaques": attaques,
    }


def generer_fiche_arme(arme_info: dict, props: list, graph: list, mapping: dict) -> dict:
    """Génère une fiche d'arme Space Dracula."""
    nom_original = arme_info["nom_original"]
    nom_sd = arme_info["nom_sd"]
    
    # Trouver les props de cette arme
    arme_props = {}
    chaines = []
    
    for p in props:
        id_ = p.get("id", "")
        if nom_original in id_:
            for key, value in p.get("props", {}).items():
                new_key = renomer_token(key, mapping)
                if new_key not in arme_props:
                    arme_props[new_key] = value
            
            # Extraire les chaînes (SwapOnFire, AddOnFire, etc.)
            for chain_key in ["SwapOnFire", "AddOnFire", "AddControlOnFire", "RemoveControlOnCharge", "ForceReleaseWeaponOnFire"]:
                if chain_key in p.get("props", {}):
                    chaines.append({
                        "type": renomer_token(chain_key, mapping),
                        "cible": renomer_token(p["props"][chain_key], mapping),
                    })
    
    # Trouver les liens dans le graphe
    liens = []
    for g in graph:
        if g.get("type") in ("sjson_entity", "lua_entity"):
            if nom_original in g.get("id", ""):
                for edge in g.get("edges", []):
                    liens.append({
                        "type": edge.get("type"),
                        "cible": renomer_token(edge.get("target", ""), mapping),
                    })
    
    return {
        "id": nom_sd,
        "nom": nom_sd,
        "categorie": "arme",
        "props": arme_props,
        "chaines": chaines,
        "liens": liens,
    }


def main():
    print("Chargement des données...")
    mapping_base = charger_mapping()
    identity = charger_identity()
    props = charger_props()
    graph = charger_graph()
    mapping = charger_mapping_complet(identity, mapping_base)
    
    print(f"  - mapping: {len(mapping)} tokens")
    print(f"  - identity: {len(identity)} entités")
    print(f"  - props: {len(props)} enregistrements")
    print(f"  - graph: {len(graph)} nœuds")
    
    # Créer le dossier de sortie
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    # Générer les fiches ennemis
    ennemis_fiches = []
    for name, info in identity.items():
        if info.get("categorie") == "ennemi":
            ennemi_info = {
                "nom_original": name,
                "nom_actuel": info.get("nom_actuel", name),
                "nom_sd": mapping.get(name, {}).get("nom_sd", name),
            }
            fiche = generer_fiche_ennemi(ennemi_info, props, mapping)
            ennemis_fiches.append(fiche)
    
    # Générer les fiches boss
    bosses_fiches = []
    for name, info in identity.items():
        if info.get("categorie") == "boss":
            boss_info = {
                "nom_original": name,
                "nom_actuel": info.get("nom_actuel", name),
                "nom_sd": mapping.get(name, {}).get("nom_sd", name),
            }
            fiche = generer_fiche_boss(boss_info, props, mapping)
            bosses_fiches.append(fiche)
    
    # Générer les fiches mini-boss
    mini_bosses_fiches = []
    for name, info in identity.items():
        if info.get("categorie") == "mini-boss":
            mini_boss_info = {
                "nom_original": name,
                "nom_actuel": info.get("nom_actuel", name),
                "nom_sd": mapping.get(name, {}).get("nom_sd", name),
            }
            fiche = generer_fiche_boss(mini_boss_info, props, mapping)
            fiche["categorie"] = "mini-boss"
            mini_bosses_fiches.append(fiche)
    
    # Générer les fiches armes
    armes_fiches = []
    for name, info in identity.items():
        if info.get("categorie") == "arme":
            arme_info = {
                "nom_original": name,
                "nom_actuel": info.get("nom_actuel", name),
                "nom_sd": mapping.get(name, {}).get("nom_sd", name),
            }
            fiche = generer_fiche_arme(arme_info, props, graph, mapping)
            armes_fiches.append(fiche)
    
    # Écrire les fiches
    with open(OUTPUT_DIR / "FICHES_ENNEMIS.json", "w", encoding="utf-8") as f:
        json.dump(ennemis_fiches, f, indent=2, ensure_ascii=False)
    
    with open(OUTPUT_DIR / "FICHES_BOSSES.json", "w", encoding="utf-8") as f:
        json.dump(bosses_fiches, f, indent=2, ensure_ascii=False)
    
    with open(OUTPUT_DIR / "FICHES_MINI_BOSSES.json", "w", encoding="utf-8") as f:
        json.dump(mini_bosses_fiches, f, indent=2, ensure_ascii=False)
    
    with open(OUTPUT_DIR / "FICHES_ARMES.json", "w", encoding="utf-8") as f:
        json.dump(armes_fiches, f, indent=2, ensure_ascii=False)
    
    print("\n=== FICHES GÉNÉRÉES ===")
    print(f"  Ennemis: {len(ennemis_fiches)}")
    print(f"  Bosses: {len(bosses_fiches)}")
    print(f"  Mini-boss: {len(mini_bosses_fiches)}")
    print(f"  Armes: {len(armes_fiches)}")
    print(f"\nÉcrit dans: {OUTPUT_DIR}")
    
    # Aperçu d'un boss
    if bosses_fiches:
        boss = bosses_fiches[0]
        print(f"\n=== APERÇU: {boss['nom']} ===")
        print(f"  Props: {len(boss['props'])}")
        print(f"  Phases: {len(boss['phases'])}")
        print(f"  Attaques: {len(boss['attaques'])}")
        if boss['phases']:
            print(f"  Première phase: {boss['phases'][0]['id']}")


if __name__ == "__main__":
    main()
