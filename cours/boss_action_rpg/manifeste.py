"""Ce que contient chaque projet d'étape du cours « boss_action_rpg ». Lu par usine/cours/jeu.py.

Demande de laurent du 2026-10-28 : « tu crées un niveau de jeu professionnel avec un rendu professionnel avec Godot
4.7, d'un niveau de BOSS action RPG à la DARK SOULS ! le rendu et la finalisation d'un code propre et extrêmement
optimisé et performant en 3D ! » ; « le héros doit tirer sur le golem » ; « change d'échelle le saloon pour qu'il soit
plus dramatique ». Le cours enseigne à Qwen comment on part de ce prompt pour arriver au jeu : chaque note d'étape
explique la démarche (ce qu'on cherche, pourquoi, comment on vérifie). Combat original du genre (conception :
`D:\\GODOT\\PROJETS_DEMOS\\PROJET_BOSS_ACTION_RPG\\SUIVIS_PROGRESSION\\conception.md`).

Le jeu source : celui du kart pour l'extension GdUnit4 tant que le jeu est en maquette grise (étapes 1 à 11) ; le
dossier du jeu lui-même (clé « boss_action_rpg » de [sources]) quand les modèles, animations et sons classés dans
`6_assets/` arrivent.
"""

GENRE = "jeu"
PREFIXE = "boss"
SOURCE = "kart"
DERNIERE = 2

ETAPES = [
    {"piste": "Architecture + Contrôles", "titre": "Le socle : nomenclature, réglages stricts, actions, ordre d'exécution"},
    {"piste": "Gameplay + Physique", "titre": "Le héros en maquette grise : courir par rapport à la caméra"},
]

EXTENSIONS = {
    "addons/gdUnit4": "1+",
}

PRETES = [1, 2]

FICHIERS = {
    "project.godot": "1+",
    "plan.md": "1+",
    "1_core/process_order.gd": "1+",
    "1_core/input/actions.gd": "1+",
    "2_sequence/main.gd": "1+",
    "2_sequence/main.tscn": "1+",
    "7_tests/1_core/silence_audio.gd": "1+",
    "7_tests/1_core/test_documentation.gd": "1+",
    "7_tests/1_core/test_process_order.gd": "1+",
    "7_tests/1_core/input/test_actions.gd": "1+",
    "7_tests/2_sequence/test_main.gd": "1+",
    "7_tests/lancer_tests.bat": "1+",
    "1_core/data/hero_settings.gd": "2+",
    "1_core/physics/motion.gd": "2+",
    "1_core/physics/layers.gd": "2+",
    "3_entities/hero/hero.gd": "2+",
    "3_entities/hero/hero_input.gd": "2+",
    "3_entities/hero/hero.tscn": "2+",
    "5_data/hero/hero_settings.tres": "2+",
    "7_tests/1_core/physics/test_motion.gd": "2+",
    "7_tests/3_entities/hero/test_hero.gd": "2+",
}
