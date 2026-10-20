#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generer_fiches.py
Génère les 123 fiches .tres (Resource) pour LOGICOR.
"""

import os
import json
from pathlib import Path

# Chemins
BASE = Path(__file__).parent.parent
DONNEES = BASE / "donnees"
ADVERSAIRES = BASE / "adversaires"
OUT = BASE / "fiches"

# Les fiches du héros
FICHES_HEROS = {
    "FicheHeros": {
        "vie_max": 30,
        "souffle_max": 50,
        "seuil_invuln": 0.25,
        "degat_min_invuln": 15,
        "fenetre_cumul": 0.6,
        "duree_invuln": 1.3,
        "dernier_effort_soin": 0.4,
        "dernier_effort_duree": 5.0,
        "dernier_effort_modif": 0.3,
        "mode_facile_base": 0.8,
        "mode_facile_mort": -0.02,
        "mode_facile_cap": 30,
        "cout_porte_secrete_base": 10.0,
        "cout_porte_secrete_ramp": 0.4,
        "seuil_combo": 12,
        "dash_duree": 0.4,
        "buffer_sprint": 0.42,
    }
}

# Les fiches des ennemis
FICHES_ENNEMIS = {
    "Unit001": {
        "nom": "Unit001",
        "vie_max": 100,
        "vitesse": 200.0,
        "portee": 120.0,
        "portee_buffer": 0.0,
        "distance_min": 0.0,
        "distance_max": 600.0,
        "repli_seuil": 0.0,
        "evasion_duree": 0.0,
        "comportement": "agressif",
        "outils": [
            {"nom": "Slam", "when": "toujours", "portee": 120.0, "apres": {"chance": 0.35, "devenir": "Charge"}},
            {"nom": "Charge", "when": "toujours", "portee": 400.0, "apres": {"chance": 1.0, "devenir": "Slam"}},
        ],
        "stades": [
            {"seuil": 1.00, "armes": ["Slam", "Charge"], "nouveau_comportement": ""},
            {"seuil": 0.30, "armes": ["Charge"], "nouveau_comportement": "furieux"},
        ],
        "difficulte_base": 50,
    },
    "Unit002": {
        "nom": "Unit002",
        "vie_max": 80,
        "vitesse": 250.0,
        "portee": 80.0,
        "portee_buffer": 0.0,
        "distance_min": 0.0,
        "distance_max": 400.0,
        "repli_seuil": 0.1,
        "evasion_duree": 0.3,
        "comportement": "eludeur",
        "outils": [
            {"nom": "CoupRapide", "when": "de_pret", "portee": 80.0, "apres": {"chance": 0.5, "devenir": "CoupRapide"}},
        ],
        "stades": [
            {"seuil": 1.00, "armes": ["CoupRapide"], "nouveau_comportement": ""},
            {"seuil": 0.50, "armes": ["CoupRapide"], "nouveau_comportement": "vif"},
        ],
        "difficulte_base": 40,
    },
    "Unit003": {
        "nom": "Unit003",
        "vie_max": 200,
        "vitesse": 150.0,
        "portee": 200.0,
        "portee_buffer": 0.0,
        "distance_min": 100.0,
        "distance_max": 800.0,
        "repli_seuil": 0.2,
        "evasion_duree": 0.0,
        "comportement": "tireur",
        "outils": [
            {"nom": "TirLoin", "when": "de_loin", "portee": 800.0, "apres": {"chance": 0.7, "devenir": "TirLoin"}},
            {"nom": "TirRapide", "when": "de_pret", "portee": 300.0, "apres": {"chance": 0.3, "devenir": "TirLoin"}},
        ],
        "stades": [
            {"seuil": 1.00, "armes": ["TirLoin", "TirRapide"], "nouveau_comportement": ""},
            {"seuil": 0.60, "armes": ["TirRapide"], "nouveau_comportement": "pressant"},
            {"seuil": 0.30, "armes": ["TirLoin", "TirRapide"], "nouveau_comportement": "furieux"},
        ],
        "difficulte_base": 60,
    },
}

# Les fiches des salles
FICHES_SALLES = {
    "Salle001": {
        "nom": "Salle001",
        "types": ["combat"],
        "delai_apparition": 0.5,
        "delai_deverrouillage": 0.4,
        "delai_fin_combat": 0.2,
        "encounters": [
            {"enemies": ["Unit001"], "count": 2, "difficulte": 50},
        ],
        "issues": ["Salle002"],
        "cout_combat": 0.0,
        "cout_vie": 0,
    },
    "Salle002": {
        "nom": "Salle002",
        "types": ["combat"],
        "delai_apparition": 0.5,
        "delai_deverrouillage": 0.4,
        "delai_fin_combat": 0.2,
        "encounters": [
            {"enemies": ["Unit001", "Unit002"], "count": 3, "difficulte": 60},
        ],
        "issues": ["Salle003"],
        "cout_combat": 5.0,
        "cout_vie": 1,
    },
    "Salle003": {
        "nom": "Salle003",
        "types": ["boss"],
        "delai_apparition": 1.0,
        "delai_deverrouillage": 0.5,
        "delai_fin_combat": 0.3,
        "encounters": [
            {"enemies": ["Unit003"], "count": 1, "difficulte": 80},
        ],
        "issues": [],
        "cout_combat": 10.0,
        "cout_vie": 2,
    },
}

# Les fiches des outils
FICHES_OUTILS = {
    "Outil001": {
        "nom": "Slam",
        "degat_base": 10,
        "degat_crit": 30,
        "portee": 120.0,
        "duree": 0.5,
        "cooldown": 0.0,
        "condition": "toujours",
    },
    "Outil002": {
        "nom": "Charge",
        "degat_base": 15,
        "degat_crit": 45,
        "portee": 400.0,
        "duree": 0.3,
        "cooldown": 0.5,
        "condition": "toujours",
    },
    "Outil003": {
        "nom": "CoupRapide",
        "degat_base": 5,
        "degat_crit": 15,
        "portee": 80.0,
        "duree": 0.2,
        "cooldown": 0.1,
        "condition": "de_pret",
    },
    "Outil004": {
        "nom": "TirLoin",
        "degat_base": 12,
        "degat_crit": 36,
        "portee": 800.0,
        "duree": 0.4,
        "cooldown": 0.3,
        "condition": "de_loin",
    },
    "Outil005": {
        "nom": "TirRapide",
        "degat_base": 8,
        "degat_crit": 24,
        "portee": 300.0,
        "duree": 0.2,
        "cooldown": 0.1,
        "condition": "de_pret",
    },
}


def generer_tres(nom: str, classe: str, donnees: dict) -> str:
    """Génère le contenu d'un fichier .tres."""
    lignes = [
        "[gd_resource type=\"Resource\" script_class=\"%s\" format=3]" % classe,
        "",
        "[ext_resource type=\"Script\" path=\"res://donnees/%s.gd\" id=\"1\"]" % nom,
        "",
        "[resource]",
        "script = ExtResource(\"1\")",
    ]
    for cle, valeur in donnees.items():
        if isinstance(valeur, str):
            lignes.append('%s = "%s"' % (cle, valeur))
        elif isinstance(valeur, bool):
            lignes.append("%s = %s" % (cle, "true" if valeur else "false"))
        elif isinstance(valeur, (int, float)):
            lignes.append("%s = %s" % (cle, valeur))
        elif isinstance(valeur, list):
            # Arrays simplifiés (pour la preuve, on stocke en JSON).
            lignes.append("%s = %s" % (cle, json.dumps(valeur)))
    return "\n".join(lignes) + "\n"


def main():
    # Créer le dossier de sortie.
    OUT.mkdir(parents=True, exist_ok=True)
    
    total = 0
    
    # Générer les fiches du héros.
    for nom, donnees in FICHES_HEROS.items():
        chemin = OUT / ("%s.tres" % nom)
        chemin.write_text(generer_tres(nom, nom, donnees), encoding="utf-8")
        print("Généré: %s" % chemin.name)
        total += 1
    
    # Générer les fiches des ennemis.
    for nom, donnees in FICHES_ENNEMIS.items():
        chemin = OUT / ("%s.tres" % nom)
        chemin.write_text(generer_tres(nom, "FicheEnnemi", donnees), encoding="utf-8")
        print("Généré: %s" % chemin.name)
        total += 1
    
    # Générer les fiches des salles.
    for nom, donnees in FICHES_SALLES.items():
        chemin = OUT / ("%s.tres" % nom)
        chemin.write_text(generer_tres(nom, "FicheSalle", donnees), encoding="utf-8")
        print("Généré: %s" % chemin.name)
        total += 1
    
    # Générer les fiches des outils.
    for nom, donnees in FICHES_OUTILS.items():
        chemin = OUT / ("%s.tres" % nom)
        chemin.write_text(generer_tres(nom, "FicheOutil", donnees), encoding="utf-8")
        print("Généré: %s" % chemin.name)
        total += 1
    
    # Générer les 108 fiches supplémentaires (Unit004 à Unit050, Salle004 à Salle050, Outil006 à Outil058).
    # 47 Unités supplémentaires (Unit004 à Unit050).
    for i in range(4, 51):
        nom = "Unit%03d" % i
        donnees = {
            "nom": nom,
            "vie_max": 80 + (i % 5) * 20,
            "vitesse": 180.0 + (i % 3) * 20.0,
            "portee": 100.0 + (i % 4) * 20.0,
            "portee_buffer": 0.0,
            "distance_min": 0.0,
            "distance_max": 500.0 + (i % 5) * 50.0,
            "repli_seuil": 0.0 + (i % 3) * 0.1,
            "evasion_duree": 0.0 + (i % 2) * 0.2,
            "comportement": ["agressif", "eludeur", "tireur", "tank"][i % 4],
            "outils": [
                {"nom": "Attaque%d" % (i % 3 + 1), "when": "toujours", "portee": 100.0 + (i % 4) * 20.0, "apres": {"chance": 0.5, "devenir": "Attaque%d" % ((i % 3) + 1)}},
            ],
            "stades": [
                {"seuil": 1.00, "armes": ["Attaque%d" % (i % 3 + 1)], "nouveau_comportement": ""},
                {"seuil": 0.50, "armes": ["Attaque%d" % (i % 3 + 1)], "nouveau_comportement": "vif"},
            ],
            "difficulte_base": 40 + (i % 5) * 10,
        }
        chemin = OUT / ("%s.tres" % nom)
        chemin.write_text(generer_tres(nom, "FicheEnnemi", donnees), encoding="utf-8")
        print("Généré: %s" % chemin.name)
        total += 1
    
    # 30 Salles supplémentaires (Salle004 à Salle033).
    for i in range(4, 34):
        nom = "Salle%03d" % i
        donnees = {
            "nom": nom,
            "types": ["combat"] if i % 5 != 0 else ["boss"],
            "delai_apparition": 0.5,
            "delai_deverrouillage": 0.4,
            "delai_fin_combat": 0.2,
            "encounters": [
                {"enemies": ["Unit%03d" % (i % 50 + 1)], "count": 1 + (i % 3), "difficulte": 50 + (i % 5) * 10},
            ],
            "issues": ["Salle%03d" % (i + 1)] if i < 33 else [],
            "cout_combat": float((i % 5) * 5),
            "cout_vie": i % 3,
        }
        chemin = OUT / ("%s.tres" % nom)
        chemin.write_text(generer_tres(nom, "FicheSalle", donnees), encoding="utf-8")
        print("Généré: %s" % chemin.name)
        total += 1
    
    # 34 Outils supplémentaires (Outil006 à Outil039).
    for i in range(6, 40):
        nom = "Outil%03d" % i
        donnees = {
            "nom": "Outil%03d" % i,
            "degat_base": 8 + (i % 5) * 2,
            "degat_crit": 24 + (i % 5) * 6,
            "portee": 80.0 + (i % 4) * 50.0,
            "duree": 0.3 + (i % 3) * 0.1,
            "cooldown": 0.1 + (i % 4) * 0.1,
            "condition": ["toujours", "de_loin", "de_pret"][i % 3],
        }
        chemin = OUT / ("%s.tres" % nom)
        chemin.write_text(generer_tres(nom, "FicheOutil", donnees), encoding="utf-8")
        print("Généré: %s" % chemin.name)
        total += 1
    
    print("\n=== %d fiches générées ===" % total)


if __name__ == "__main__":
    main()
