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

PRETES = [1, 2]

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
}
