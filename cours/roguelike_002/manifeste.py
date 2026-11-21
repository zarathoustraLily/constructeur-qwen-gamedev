"""Ce que contient chaque projet d'étape du cours « roguelike_002 ». Lu par usine/cours/jeu.py.

Le jeu : un roguelike en demi 3D, thème vaisseau spatial (`PROJET_ROGUE_LIKE_002`), codé pour le cours d'après la
charte de laurent (`000-charte-de-codage.txt`) et son plan (`PLAN_JEU_BUT_EXEMPLE.md`, 26 unités). Aucune donnée,
salle, texture ni texte d'un jeu existant : les mécaniques du plan seulement, avec nos valeurs et des assets fictifs.

Ordre des étapes : `PLAN_DU_COURS.md` (35 étapes) mettait les menus aux étapes 22 à 27. laurent, le 2026-11-21 :
« deja on fait le menu : gestion du chargement avec le nom de la boite , deuxieme panneau le disclamer, 3 eme partie le
motion diseing et le menu du jeu avec le trie le options et la gensitons des sauvegardes ». Les menus viennent donc
d'abord, juste après le socle ; les étapes de jeu du plan suivront.

Le jeu source (clé « roguelike_002 » de [sources]) fournit GdUnit4 et les assets fictifs.
"""

GENRE = "jeu"
PREFIXE = "roguelike2"
SOURCE = "roguelike_002"
DERNIERE = 6

ETAPES = [
    {"piste": "Architecture + Contrôle à la manette", "titre": "Le socle : huit dossiers, réglages stricts, ordre d'exécution, hasard injecté, entrées clavier et manette, la coquille qui enchaîne les écrans"},
    {"piste": "UI + Gestion de la mémoire", "titre": "L'écran du studio : le nom de la boîte pendant un vrai chargement en fond, la barre suit le chargement"},
    {"piste": "UI + Contrôle à la manette", "titre": "L'avertissement : le texte, puis un bouton pour le passer, au clavier et à la manette"},
    {"piste": "UI + Graphisme 2D", "titre": "Le menu principal en motion design : le titre et les boutons entrent en mouvement, le fond glisse, la manette navigue"},
    {"piste": "UI + Audio", "titre": "Les options : difficulté, définition, plein écran, volumes ; enregistrées, appliquées, et un retour"},
    {"piste": "UI + Gestion de la mémoire", "titre": "Les sauvegardes : quatre emplacements, partie neuve, chargement, effacement confirmé ; versionnées, écriture atomique"},
]

EXTENSIONS = {
    "addons/gdUnit4": "1+",
}

PRETES = [1, 2, 3, 4, 5, 6]

FICHIERS = {
    "project.godot": "1+",
    "plan.md": "1+",
    "1_core/process_order.gd": "1+",
    "1_core/jeu/rng_source.gd": "1+",
    "1_core/data/sequence_def.gd": "1+",
    "5_data/jeu/sequence.tres": "1+",
    "2_sequence/jeu/main.gd": "1+",
    "2_sequence/jeu/main.tscn": "1+",
    "7_tests/lancer_tests.bat": "1+",
    "7_tests/1_core/test_documentation.gd": "1+",
    "7_tests/1_core/test_process_order.gd": "1+",
    "7_tests/1_core/test_entrees.gd": "1+",
    "7_tests/1_core/jeu/test_rng_source.gd": "1+",
    "7_tests/1_core/data/test_sequence_def.gd": "1+",
    "7_tests/2_sequence/jeu/test_main.gd": "1+",
    "7_tests/2_sequence/jeu/ecran_temoin.gd": "1+",
    "7_tests/2_sequence/jeu/ecran_temoin.tscn": "1+",
    "1_core/jeu/background_loader.gd": "2+",
    "1_core/data/studio_def.gd": "2+",
    "5_data/jeu/studio.tres": "2+",
    "2_sequence/jeu/studio_screen.gd": "2+",
    "2_sequence/jeu/studio_screen.tscn": "2+",
    "4_ui/jeu/studio_view.gd": "2+",
    "7_tests/1_core/jeu/test_background_loader.gd": "2+",
    "7_tests/1_core/data/test_studio_def.gd": "2+",
    "7_tests/2_sequence/jeu/test_studio_screen.gd": "2+",
    "1_core/data/disclaimer_def.gd": "3+",
    "5_data/jeu/avertissement.tres": "3+",
    "2_sequence/jeu/disclaimer_screen.gd": "3+",
    "2_sequence/jeu/disclaimer_screen.tscn": "3+",
    "4_ui/jeu/disclaimer_view.gd": "3+",
    "4_ui/jeu/disclaimer_input.gd": "3+",
    "7_tests/1_core/data/test_disclaimer_def.gd": "3+",
    "7_tests/4_ui/jeu/test_disclaimer_input.gd": "3+",
    "7_tests/2_sequence/jeu/test_disclaimer_screen.gd": "3+",
    "1_core/data/menu_def.gd": "4+",
    "5_data/jeu/menu.tres": "4+",
    "2_sequence/jeu/menu_screen.gd": "4+",
    "2_sequence/jeu/menu_screen.tscn": "4+",
    "4_ui/jeu/menu_view.gd": "4+",
    "7_tests/1_core/data/test_menu_def.gd": "4+",
    "7_tests/2_sequence/jeu/test_menu_screen.gd": "4+",
    "1_core/data/options_def.gd": "5+",
    "1_core/jeu/game_settings.gd": "5+",
    "1_core/jeu/settings_applier.gd": "5+",
    "5_data/jeu/options.tres": "5+",
    "6_assets/jeu/audio/bus_layout.tres": "5+",
    "6_assets/jeu/ui/theme_options.tres": "5+",
    "2_sequence/jeu/options_screen.gd": "5+",
    "2_sequence/jeu/options_screen.tscn": "5+",
    "4_ui/jeu/options_view.gd": "5+",
    "4_ui/jeu/options_input.gd": "5+",
    "7_tests/1_core/data/test_options_def.gd": "5+",
    "7_tests/1_core/jeu/test_game_settings.gd": "5+",
    "7_tests/1_core/jeu/test_settings_applier.gd": "5+",
    "7_tests/2_sequence/jeu/test_options_screen.gd": "5+",
    "1_core/ui/focus_chain.gd": "6+",
    "1_core/data/saves_def.gd": "6+",
    "1_core/jeu/save_system.gd": "6+",
    "5_data/jeu/sauvegardes.tres": "6+",
    "2_sequence/jeu/saves_screen.gd": "6+",
    "2_sequence/jeu/saves_screen.tscn": "6+",
    "4_ui/jeu/saves_view.gd": "6+",
    "4_ui/jeu/saves_input.gd": "6+",
    "7_tests/1_core/data/test_saves_def.gd": "6+",
    "7_tests/1_core/jeu/test_save_system.gd": "6+",
    "7_tests/2_sequence/jeu/test_saves_screen.gd": "6+",
}
