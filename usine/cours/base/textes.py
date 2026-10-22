"""Textes fixes de la base : message système (rôle et plan), présentation des projets."""
from __future__ import annotations


# Le plan en huit dossiers : tableau des règles de laurent (Règles1, section « Dossiers »), colonnes
# « Dossier » et « Contient » recopiées sans changement.
PLAN = """| Dossier | Contient |
| --- | --- |
| `0_autoload/` | Services globaux persistants : déroulement, état de partie, événements partagés, audio global, traces |
| `1_core/` | Mécanismes et contrats génériques : composants, types de Resource, table des priorités d'exécution, résolution de dégâts |
| `2_sequence/` | Ordre des étapes et leur réalisation : cinématiques, menus, niveaux, leur ouverture et leur fermeture |
| `3_entities/` | Joueur, ennemis, boss, projectiles : logique propre et présentation, dans des scripts distincts |
| `4_ui/` | HUD, interfaces superposées, composants d'interface |
| `5_data/` | Paramètres de conception : caractéristiques, armes, vagues, réglages |
| `6_assets/` | Modèles, textures, audio, shaders, matériaux, polices |
| `7_tests/` | Tests, en miroir des éléments testés |"""

SYSTEME = f"""Tu es un développeur Godot 4.7.2 : GDScript typé et shaders. Tu travailles dans un projet existant, rangé selon ce plan ; chaque fichier va dans le dossier que le plan lui donne :

{PLAN}

Dans ce projet, les bâtiments procéduraux suivent ces chemins :
- générateurs (scripts `@tool`) et scènes : `6_assets/Mesh/Procedural/DECORS/Building/` ;
- shaders : `6_assets/Shader/Procedural/DECORS/Building/` ;
- données (palettes, listes, cotes) : `5_data/DECORS/Building/` ;
- outils communs : `1_core/procedural/` ; tests : `7_tests/`, en miroir du fichier testé."""

VILLES = {
    "parisien": ("un immeuble parisien procédural, de style haussmannien", "l'immeuble"),
    "tokyoiste": ("un petit immeuble de Tokyo procédural, sur une parcelle étroite", "l'immeuble"),
    "newyorkais": ("une tour de bureaux new-yorkaise procédurale, dans un quartier d'affaires", "la tour"),
}

# Les cours « de jeu » : le même plan, et ce que le projet a de propre (tests GdUnit4, avertissements en erreurs).
SYSTEME_JEU = f"""Tu es un développeur Godot 4.7.2 : GDScript typé et shaders. Tu travailles dans un projet existant, rangé selon ce plan ; chaque fichier va dans le dossier que le plan lui donne :

{PLAN}

Dans ce projet :
- les tests sont des suites GdUnit4 (`extends GdUnitTestSuite`) dans `7_tests/`, en miroir du fichier testé ; GdUnit4 est dans `addons/gdUnit4/` ;
- les avertissements de GDScript sont des erreurs (bloc `[debug]` de `project.godot`), typage compris ;
- la logique ne lit pas les entrées : un script `<nom>_input.gd` lit `Input` et donne des commandes ; la présentation (sons, particules, animations) va dans un script `<nom>_view.gd`."""

# Le projet de chaque cours de jeu, tel que la demande le présente (d'après la note de sa première étape).
JEUX = {
    "kart": ("un jeu de kart sur une île, au clavier et à la manette : eau, herbe, effets et objets", "le jeu"),
    "roguelike": ("un roguelike d'action en 3D, au clavier, à la souris et à la manette : combat, ennemis, vagues et "
                  "boutique", "le jeu"),
}


def systeme() -> str:
    """Le message système du format neutre, selon le cours."""
    from usine.cours.base import chemins
    return SYSTEME_JEU if chemins.actuels().jeu else SYSTEME


def projet(ville: str) -> tuple[str, str]:
    """(présentation du projet, son nom court) : une ville des bâtiments, ou un cours de jeu (son préfixe)."""
    return JEUX[ville] if ville in JEUX else VILLES[ville]
