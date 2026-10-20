#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
convertir_json_tres.py
Convertit les fiches JSON Space Dracula en fichiers .tres Godot 4.x.
Format correct avec [resource] et liaison du script.
Les clés de dictionnaires avec points sont converties en underscores.
"""

import json
import re
from pathlib import Path

FICHES_DIR = Path(__file__).parent.parent / "space_dracula" / "fiches"
OUTPUT_DIR = Path(__file__).parent.parent / "donnees"


def id_partie(id: str) -> str:
    """Extrait la partie numérique de l'ID pour le UID."""
    match = re.search(r"(\d+)", id)
    return match.group(1) if match else "0"


def nettoyer_cle(cle: str) -> str:
    """Remplace les points dans les clés par des underscores."""
    return cle.replace(".", "_")


def serialiser_valeur_tres(valeur) -> str:
    """Serialise une valeur Python en format Godot .tres."""
    if valeur is None:
        return "null"
    elif isinstance(valeur, bool):
        return "true" if valeur else "false"
    elif isinstance(valeur, int):
        return str(valeur)
    elif isinstance(valeur, float):
        return f"{valeur}"
    elif isinstance(valeur, str):
        valeur_echap = valeur.replace('"', '\\"')
        return f'"{valeur_echap}"'
    elif isinstance(valeur, list):
        if not valeur:
            return "[]"
        items = [serialiser_valeur_tres(item) for item in valeur]
        return f"[{', '.join(items)}]"
    elif isinstance(valeur, dict):
        if not valeur:
            return "{}"
        items = [f'"{nettoyer_cle(str(k))}": {serialiser_valeur_tres(v)}' for k, v in valeur.items()]
        return "{ " + ", ".join(items) + " }"
    else:
        return str(valeur)


def generer_tres_ennemi(fiche: dict) -> str:
    """Génère le contenu d'un fichier .tres pour un ennemi."""
    id = fiche["id"]
    
    props = fiche.get("props", {})
    arsenal = fiche.get("arsenal", [])
    
    lignes = []
    lignes.append(f'[gd_resource type="Resource" script_class="FicheEnnemi" format=3]')
    lignes.append("")
    lignes.append(f'[ext_resource type="Script" path="res://donnees/FicheEnnemi.gd" id="1"]')
    lignes.append("")
    lignes.append("[resource]")
    lignes.append('script = ExtResource("1")')
    lignes.append(f'id = "{id}"')
    lignes.append(f'nom = "{fiche.get("nom", id)}"')
    lignes.append(f'categorie = "{fiche.get("categorie", "ennemi")}"')
    
    if "PV_Max" in props:
        lignes.append(f'PV_Max = {props["PV_Max"]}')
    if "Vitesse" in props:
        v = props["Vitesse"]
        if isinstance(v, float):
            lignes.append(f'Vitesse = {v}')
        else:
            lignes.append(f'Vitesse = {float(v)}')
    if "NoteDifficulte" in props:
        lignes.append(f'NoteDifficulte = {props["NoteDifficulte"]}')
    if "PoidsPiscine" in props:
        lignes.append(f'PoidsPiscine = {props["PoidsPiscine"]}')
    if "PoidsPlafondActif" in props:
        lignes.append(f'PoidsPlafondActif = {props["PoidsPlafondActif"]}')
    if "ModificateurCassureEtourdissement" in props:
        lignes.append(f'ModificateurCassureEtourdissement = {props["ModificateurCassureEtourdissement"]}')
    if "ModificateurEffetRalentissement" in props:
        lignes.append(f'ModificateurEffetRalentissement = {props["ModificateurEffetRalentissement"]}')
    
    ia_mapping = {
        "IA_PorteeAggro": "IA_PorteeAggro",
        "IA_DelaiEveil": "IA_DelaiEveil",
        "IA_DelaiSetupIA": "IA_DelaiSetupIA",
        "IA_MaxAttaquants": "IA_MaxAttaquants",
        "IA_DistanceEntourer": "IA_DistanceEntourer",
        "IA_DistanceEntourerRiposte": "IA_DistanceEntourerRiposte",
        "IA_IntervalleRafraichissementEntourer": "IA_IntervalleRafraichissementEntourer",
        "IA_FinSeuilPV": "IA_FinSeuilPV",
        "IA_TamponRecul": "IA_TamponRecul",
    }
    
    for cle_json, cle_gd in ia_mapping.items():
        if cle_json in props:
            valeur = props[cle_json]
            if isinstance(valeur, float):
                lignes.append(f'{cle_gd} = {valeur}')
            elif isinstance(valeur, int):
                lignes.append(f'{cle_gd} = {valeur}')
            else:
                lignes.append(f'{cle_gd} = {float(valeur)}')
    
    if arsenal:
        arsenal_str = ", ".join([f'"{a}"' for a in arsenal])
        lignes.append(f'arsenal = [{arsenal_str}]')
    else:
        lignes.append('arsenal = []')
    
    return "\n".join(lignes) + "\n"


def generer_tres_boss(fiche: dict) -> str:
    """Génère le contenu d'un fichier .tres pour un boss."""
    id = fiche["id"]
    
    props = fiche.get("props", {})
    phases = fiche.get("phases", [])
    attaques = fiche.get("attaques", [])
    
    lignes = []
    lignes.append(f'[gd_resource type="Resource" script_class="FicheBoss" format=3]')
    lignes.append("")
    lignes.append('[ext_resource type="Script" path="res://donnees/FicheBoss.gd" id="1"]')
    lignes.append("")
    lignes.append("[resource]")
    lignes.append('script = ExtResource("1")')
    lignes.append(f'id = "{id}"')
    lignes.append(f'nom = "{fiche.get("nom", id)}"')
    lignes.append(f'categorie = "{fiche.get("categorie", "boss")}"')
    
    if "PV_Max" in props:
        lignes.append(f'PV_Max = {props["PV_Max"]}')
    if "Vitesse" in props:
        v = props["Vitesse"]
        if isinstance(v, float):
            lignes.append(f'Vitesse = {v}')
        else:
            lignes.append(f'Vitesse = {float(v)}')
    if "NoteDifficulte" in props:
        lignes.append(f'NoteDifficulte = {props["NoteDifficulte"]}')
    if "TamponPV" in props:
        lignes.append(f'TamponPV = {props["TamponPV"]}')
    
    ia_mapping = {
        "IA_PorteeAggro": "IA_PorteeAggro",
        "IA_DelaiEveil": "IA_DelaiEveil",
        "IA_DelaiSetupIA": "IA_DelaiSetupIA",
        "IA_MaxAttaquants": "IA_MaxAttaquants",
        "IA_DistanceEntourer": "IA_DistanceEntourer",
        "IA_IntervalleRafraichissementEntourer": "IA_IntervalleRafraichissementEntourer",
        "IA_FinSeuilPV": "IA_FinSeuilPV",
    }
    
    for cle_json, cle_gd in ia_mapping.items():
        if cle_json in props:
            valeur = props[cle_json]
            if isinstance(valeur, float):
                lignes.append(f'{cle_gd} = {valeur}')
            elif isinstance(valeur, int):
                lignes.append(f'{cle_gd} = {valeur}')
            else:
                lignes.append(f'{cle_gd} = {float(valeur)}')
    
    if phases:
        phases_items = []
        for p in phases:
            p_id = p.get("id", "")
            p_props = p.get("props", {})
            p_props_str = serialiser_valeur_tres(p_props)
            phases_items.append(f'{{ "id": "{p_id}", "props": {p_props_str} }}')
        lignes.append(f'phases = [{", ".join(phases_items)}]')
    else:
        lignes.append('phases = []')
    
    if attaques:
        attaques_items = []
        for a in attaques:
            a_id = a.get("id", "")
            a_props = a.get("props", {})
            a_props_str = serialiser_valeur_tres(a_props)
            attaques_items.append(f'{{ "id": "{a_id}", "props": {a_props_str} }}')
        lignes.append(f'attaques = [{", ".join(attaques_items)}]')
    else:
        lignes.append('attaques = []')
    
    return "\n".join(lignes) + "\n"


def generer_tres_arme(fiche: dict) -> str:
    """Génère le contenu d'un fichier .tres pour une arme."""
    id = fiche["id"]
    
    props = fiche.get("props", {})
    
    lignes = []
    lignes.append(f'[gd_resource type="Resource" script_class="FicheArme" format=3]')
    lignes.append("")
    lignes.append('[ext_resource type="Script" path="res://donnees/FicheArme.gd" id="1"]')
    lignes.append("")
    lignes.append("[resource]")
    lignes.append('script = ExtResource("1")')
    lignes.append(f'id = "{id}"')
    lignes.append(f'nom = "{fiche.get("nom", id)}"')
    lignes.append(f'categorie = "{fiche.get("categorie", "arme")}"')
    if "numero" in fiche:
        lignes.append(f'numero = {fiche["numero"]}')
    
    if props:
        lignes.append(f'props = {serialiser_valeur_tres(props)}')
    else:
        lignes.append('props = {}')
    
    return "\n".join(lignes) + "\n"


def generer_tres_mini_boss(fiche: dict) -> str:
    """Génère le contenu d'un fichier .tres pour un mini-boss."""
    id = fiche["id"]
    
    props = fiche.get("props", {})
    phases = fiche.get("phases", [])
    attaques = fiche.get("attaques", [])
    
    lignes = []
    lignes.append(f'[gd_resource type="Resource" script_class="FicheMiniBoss" format=3]')
    lignes.append("")
    lignes.append('[ext_resource type="Script" path="res://donnees/FicheMiniBoss.gd" id="1"]')
    lignes.append("")
    lignes.append("[resource]")
    lignes.append('script = ExtResource("1")')
    lignes.append(f'id = "{id}"')
    lignes.append(f'nom = "{fiche.get("nom", id)}"')
    lignes.append(f'categorie = "{fiche.get("categorie", "mini-boss")}"')
    
    if "PV_Max" in props:
        lignes.append(f'PV_Max = {props["PV_Max"]}')
    if "Vitesse" in props:
        v = props["Vitesse"]
        lignes.append(f'Vitesse = {float(v) if isinstance(v, (int, float)) else 400.0}')
    if "NoteDifficulte" in props:
        lignes.append(f'NoteDifficulte = {props["NoteDifficulte"]}')
    if "TamponPV" in props:
        lignes.append(f'TamponPV = {props["TamponPV"]}')
    
    ia_mapping = {
        "IA_PorteeAggro": "IA_PorteeAggro",
        "IA_DelaiEveil": "IA_DelaiEveil",
        "IA_DelaiSetupIA": "IA_DelaiSetupIA",
        "IA_MaxAttaquants": "IA_MaxAttaquants",
        "IA_DistanceEntourer": "IA_DistanceEntourer",
        "IA_IntervalleRafraichissementEntourer": "IA_IntervalleRafraichissementEntourer",
        "IA_FinSeuilPV": "IA_FinSeuilPV",
    }
    
    for cle_json, cle_gd in ia_mapping.items():
        if cle_json in props:
            valeur = props[cle_json]
            lignes.append(f'{cle_gd} = {valeur if isinstance(valeur, (int, float)) else float(valeur)}')
    
    if phases:
        phases_items = []
        for p in phases:
            p_id = p.get("id", "")
            p_props = p.get("props", {})
            p_props_str = serialiser_valeur_tres(p_props)
            phases_items.append(f'{{ "id": "{p_id}", "props": {p_props_str} }}')
        lignes.append(f'phases = [{", ".join(phases_items)}]')
    else:
        lignes.append('phases = []')
    
    if attaques:
        attaques_items = []
        for a in attaques:
            a_id = a.get("id", "")
            a_props = a.get("props", {})
            a_props_str = serialiser_valeur_tres(a_props)
            attaques_items.append(f'{{ "id": "{a_id}", "props": {a_props_str} }}')
        lignes.append(f'attaques = [{", ".join(attaques_items)}]')
    else:
        lignes.append('attaques = []')
    
    # Props bruts (tout ce qui n'est pas déjà extrait)
    cles_deja = {"PV_Max", "Vitesse", "NoteDifficulte", "TamponPV", "IA_PorteeAggro", "IA_DelaiEveil", "IA_DelaiSetupIA", "IA_MaxAttaquants", "IA_DistanceEntourer", "IA_IntervalleRafraichissementEntourer", "IA_FinSeuilPV"}
    props_restants = {k: v for k, v in props.items() if k not in cles_deja}
    if props_restants:
        lignes.append(f'props = {serialiser_valeur_tres(props_restants)}')
    else:
        lignes.append('props = {}')
    
    return "\n".join(lignes) + "\n"


def generer_tres_salle(fiche: dict) -> str:
    """Génère le contenu d'un fichier .tres pour une salle."""
    id = fiche["id"]
    
    profil = fiche.get("profil", {})
    pool = fiche.get("pool", [])
    
    lignes = []
    lignes.append('[gd_resource type="Resource" script_class="FicheSalle" format=3]')
    lignes.append("")
    lignes.append('[ext_resource type="Script" path="res://donnees/FicheSalle.gd" id="1"]')
    lignes.append("")
    lignes.append("[resource]")
    lignes.append('script = ExtResource("1")')
    lignes.append(f'id = "{id}"')
    lignes.append(f'nom = "{fiche.get("nom", id)}"')
    lignes.append(f'niveau = {fiche.get("niveau", 1)}')
    lignes.append(f'profil_nom = "{fiche.get("profil_nom", "")}"')
    
    # Profil
    profil_mapping = {
        "DifficulteDeBase": "difficulte_de_base",
        "RampDifficulteParProfondeur": "ramp_difficulte_par_profondeur",
        "PlafondEnnemisDeBase": "plafond_ennemis_de_base",
        "RampPlafondParProfondeur": "ramp_plafond_par_profondeur",
        "PlafondEnnemisMax": "plafond_ennemis_max",
        "TypesMin": "types_min",
        "TypesMax": "types_max",
        "PlafondTypes": "plafond_types",
        "RampTypesParProfondeur": "ramp_types_par_profondeur",
        "EliteTypesMax": "elite_types_max",
        "VaguesMin": "vagues_min",
        "VaguesMax": "vagues_max",
        "IntervalleSpawnMin": "intervalle_spawn_min",
        "IntervalleSpawnMax": "intervalle_spawn_max",
    }
    for cle_json, cle_gd in profil_mapping.items():
        if cle_json in profil:
            v = profil[cle_json]
            if isinstance(v, float):
                lignes.append(f'{cle_gd} = {v}')
            else:
                lignes.append(f'{cle_gd} = {v}')
    
    # Pool
    if pool:
        items = []
        for e in pool:
            items.append(f'{{ "ref": "{e["ref"]}", "poids": {e["poids"]}, "elite": {"true" if e["elite"] else "false"} }}')
        lignes.append(f'pool = [{", ".join(items)}]')
    else:
        lignes.append('pool = []')
    
    lignes.append(f'total_poids = {fiche.get("total_poids", 0)}')
    lignes.append(f'nb_types = {fiche.get("nb_types", 0)}')
    
    return "\n".join(lignes) + "\n"


def main():
    print("Conversion des fiches JSON en .tres Godot...")
    
    ennemis = json.load(open(FICHES_DIR / "FICHES_ENNEMIS_V2.json", encoding="utf-8"))
    bosses = json.load(open(FICHES_DIR / "FICHES_BOSSES_V2.json", encoding="utf-8"))
    armes = json.load(open(FICHES_DIR / "FICHES_ARMES_V2.json", encoding="utf-8"))
    mini_bosses = json.load(open(FICHES_DIR / "FICHES_MINI_BOSSES_V2.json", encoding="utf-8"))
    salles = json.load(open(FICHES_DIR / "FICHES_SALLES_V2.json", encoding="utf-8"))
    
    print(f"  Ennemis: {len(ennemis)}")
    print(f"  Bosses: {len(bosses)}")
    print(f"  Armes: {len(armes)}")
    print(f"  Mini-bosses: {len(mini_bosses)}")
    print(f"  Salles: {len(salles)}")
    
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    for fichier in OUTPUT_DIR.glob("CRT-*.tres"):
        fichier.unlink()
    for fichier in OUTPUT_DIR.glob("ANO-*.tres"):
        fichier.unlink()
    for fichier in OUTPUT_DIR.glob("REL-*.tres"):
        fichier.unlink()
    for fichier in OUTPUT_DIR.glob("MIN-*.tres"):
        fichier.unlink()
    for fichier in OUTPUT_DIR.glob("SLA-*.tres"):
        fichier.unlink()
    
    for ennemi in ennemis:
        id = ennemi["id"]
        contenu = generer_tres_ennemi(ennemi)
        (OUTPUT_DIR / f"{id}.tres").write_text(contenu, encoding="utf-8")
    
    for boss in bosses:
        id = boss["id"]
        contenu = generer_tres_boss(boss)
        (OUTPUT_DIR / f"{id}.tres").write_text(contenu, encoding="utf-8")
    
    for arme in armes:
        id = arme["id"]
        contenu = generer_tres_arme(arme)
        (OUTPUT_DIR / f"{id}.tres").write_text(contenu, encoding="utf-8")
    
    for mb in mini_bosses:
        id = mb["id"]
        contenu = generer_tres_mini_boss(mb)
        (OUTPUT_DIR / f"{id}.tres").write_text(contenu, encoding="utf-8")
    
    for salle in salles:
        id = salle["id"]
        contenu = generer_tres_salle(salle)
        (OUTPUT_DIR / f"{id}.tres").write_text(contenu, encoding="utf-8")
    
    print(f"\n=== FICHES .tres GÉNÉRÉES ===")
    print(f"  Ennemis: {len(ennemis)} fichiers")
    print(f"  Bosses: {len(bosses)} fichiers")
    print(f"  Armes: {len(armes)} fichiers")
    print(f"  Mini-bosses: {len(mini_bosses)} fichiers")
    print(f"  Salles: {len(salles)} fichiers")
    total = len(ennemis) + len(bosses) + len(armes) + len(mini_bosses) + len(salles)
    print(f"  Total: {total} fichiers")
    print(f"\nÉcrit dans: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
