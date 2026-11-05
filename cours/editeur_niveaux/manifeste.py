"""Ce que contient chaque projet d'étape du cours « editeur_niveaux ». Lu par usine/cours/jeu.py.

Demandes de laurent du 2026-11-05 :
- « fais le cours et le débogage de l'éditeur de jeu » ; « oui vas-y c'est important » ;
- format de salle propre au cours (choix « Format à nous ») ;
- « tu vérifies bien que ça peut fonctionner avec le jeu rogue_like_002 et que ça permettra de paramétrer le jeu,
  d'éditer les niveaux, les FX, les animations, les collisions, les spawns, de choisir les ennemis » ;
- « un carré bleu autour du sprite pour le manipuler comme sur Photoshop, pour le scaler ou le faire tourner ou le
  déplacer, et choisir son niveau de profondeur ».

L'éditeur reprend l'architecture de la charte de laurent (`PROJET_ROGUE_LIKE_002/000-charte-de-codage.txt`, §5) et
vit dans le projet du jeu (§0) : `1_core/editor/`, `2_sequence/editor/`, `4_ui/editor/`. Il lit les classes de
données du jeu (`1_core/data/`) et ses `.tres` (`5_data/`) ; il se lance comme une scène à part, hors de l'export.
Le code est écrit pour le cours : celui de l'éditeur fait avec ChatGPT n'est pas repris, son format de salle non plus.

Le jeu source (clé « editeur_niveaux » de [sources]) fournit GdUnit4 et la planche d'assets fictifs ; les salles, le
catalogue, les ennemis et les effets d'exemple sont des maîtres, fabriqués par `outils/fabriquer_exemple.py`.
"""

GENRE = "jeu"
PREFIXE = "editeur"
SOURCE = "editeur_niveaux"
DERNIERE = 18

ETAPES = [
    {"piste": "Architecture + UI", "titre": "Le socle : nomenclature, réglages stricts, ordre d'exécution, la coquille qui s'ouvre"},
    {"piste": "Architecture + Gestion de la mémoire", "titre": "La salle en données : tableaux compacts, validation, enregistrement atomique, aller-retour à l'octet"},
    {"piste": "Architecture", "titre": "Le document en mémoire : choses par identifiant stable, sélection, annulation"},
    {"piste": "Architecture + Graphisme 2D", "titre": "Le catalogue des assets : planche, région, taille en jeu, ancre, recherche"},
    {"piste": "Architecture", "titre": "Les actions annulables : déplacer, tourner, mettre à l'échelle, dupliquer, supprimer, calque, profondeur"},
    {"piste": "Graphisme 2D + Optimisation", "titre": "La vue de dessus : zoom, déplacement, écran et monde, sprites depuis la planche, ordre de dessin"},
    {"piste": "UI + Graphisme 2D", "titre": "Le cadre bleu : poignées d'échelle, poignée de rotation, glisser, sélection au rectangle, profondeur"},
    {"piste": "UI", "titre": "Les panneaux : palette avec recherche, inspecteur, hiérarchie par calque, raccourcis"},
    {"piste": "Architecture + UI", "titre": "L'orchestration : ouvrir une salle, enregistrer après validation, messages"},
    {"piste": "Physique + UI", "titre": "Les collisions : polygones infranchissables, sommets, validation"},
    {"piste": "Gameplay + UI", "titre": "Les apparitions et les rencontres : départ du héros, points par rôle, choix des ennemis"},
    {"piste": "VFX + UI", "titre": "Les effets placés : émetteurs du catalogue d'effets, aperçu dans la vue"},
    {"piste": "Architecture + UI", "titre": "Les paramètres du jeu : éditer les définitions de 5_data, validées avant d'écrire"},
    {"piste": "Graphisme 3D + Architecture", "titre": "Les animations : définitions (état vers clip, vitesses), vérifiées sur le modèle"},
    {"piste": "Graphisme 3D + VFX + Contrôles", "titre": "Le banc d'essai : modèles, clips, transitions et effets en aperçu"},
    {"piste": "Architecture", "titre": "Les salles du projet : liste, nouvelle salle, identifiants stables"},
    {"piste": "Plugins et leur usage + Architecture", "titre": "Les versions : git local, une version par salle, rien d'automatique"},
    {"piste": "Gameplay + Architecture", "titre": "La salle dans le jeu : une scène de jeu charge la salle éditée, hors de l'export"},
]

EXTENSIONS = {
    "addons/gdUnit4": "1+",
}

PRETES = [1, 2]

FICHIERS = {
    "project.godot": "1+",
    "plan.md": "1+",
    "1_core/process_order.gd": "1+",
    "2_sequence/editor/editor_shell.gd": "1+",
    "2_sequence/editor/editor_shell.tscn": "1+",
    "7_tests/1_core/test_documentation.gd": "1+",
    "7_tests/1_core/test_process_order.gd": "1+",
    "7_tests/2_sequence/editor/test_editor_shell.gd": "1+",
    "7_tests/lancer_tests.bat": "1+",
    "1_core/data/room_data.gd": "2+",
    "1_core/editor/room_store.gd": "2+",
    "1_core/editor/stable_saver.gd": "2+",
    "5_data/salles/hangar.tres": "2+",
    "5_data/salles/soute.tres": "2+",
    "5_data/salles/pont.tres": "2+",
    "7_tests/1_core/data/test_room_data.gd": "2+",
    "7_tests/1_core/editor/test_room_store.gd": "2+",
    "7_tests/1_core/editor/test_stable_saver.gd": "2+",
}
