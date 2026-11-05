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

PRETES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]

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
    "1_core/editor/undo_stack.gd": "3+",
    "1_core/editor/selection_model.gd": "3+",
    "1_core/editor/room_document.gd": "3+",
    "7_tests/1_core/editor/test_undo_stack.gd": "3+",
    "7_tests/1_core/editor/test_selection_model.gd": "3+",
    "7_tests/1_core/editor/test_room_document.gd": "3+",
    "1_core/data/asset_def.gd": "4+",
    "1_core/data/asset_catalog_def.gd": "4+",
    "1_core/editor/asset_search.gd": "4+",
    "5_data/catalogue/catalogue.tres": "4+",
    "7_tests/1_core/data/test_asset_catalog_def.gd": "4+",
    "7_tests/1_core/editor/test_asset_search.gd": "4+",
    "1_core/data/editor_settings_def.gd": "5+",
    "1_core/editor/editor_actions.gd": "5+",
    "5_data/editeur/reglages.tres": "5+",
    "7_tests/1_core/editor/test_editor_actions.gd": "5+",
    "1_core/editor/view_transform.gd": "6+",
    "1_core/editor/draw_order.gd": "6+",
    "4_ui/editor/room_view.gd": "6+",
    "4_ui/editor/room_view_input.gd": "6+",
    "7_tests/1_core/editor/test_view_transform.gd": "6+",
    "7_tests/1_core/editor/test_draw_order.gd": "6+",
    "7_tests/4_ui/editor/test_room_view.gd": "6+",
    "7_tests/4_ui/editor/test_room_view_input.gd": "6+",
    "1_core/editor/transform_gizmo.gd": "7+",
    "4_ui/editor/selection_input.gd": "7+",
    "4_ui/editor/selection_overlay.gd": "7+",
    "7_tests/1_core/editor/test_transform_gizmo.gd": "7+",
    "7_tests/4_ui/editor/test_selection_input.gd": "7+",
    "4_ui/editor/palette_panel.gd": "8+",
    "4_ui/editor/hierarchy_panel.gd": "8+",
    "4_ui/editor/inspector_panel.gd": "8+",
    "4_ui/editor/editor_shortcuts_input.gd": "8+",
    "7_tests/4_ui/editor/test_panels.gd": "8+",
    "7_tests/4_ui/editor/test_editor_shortcuts_input.gd": "8+",
    "1_core/editor/collision_tools.gd": "10+",
    "4_ui/editor/collision_view.gd": "10+",
    "4_ui/editor/collision_input.gd": "10+",
    "7_tests/1_core/editor/test_collision_tools.gd": "10+",
    "7_tests/4_ui/editor/test_collision_input.gd": "10+",
    "1_core/data/enemy_def.gd": "11+",
    "1_core/editor/definition_folder.gd": "11+",
    "4_ui/editor/spawn_input.gd": "11+",
    "4_ui/editor/spawn_view.gd": "11+",
    "4_ui/editor/encounter_panel.gd": "11+",
    "5_data/ennemis/bombe.tres": "11+",
    "5_data/ennemis/brute.tres": "11+",
    "5_data/ennemis/cone.tres": "11+",
    "5_data/ennemis/melee.tres": "11+",
    "5_data/ennemis/racine.tres": "11+",
    "5_data/ennemis/tireur.tres": "11+",
    "5_data/ennemis/toupie.tres": "11+",
    "7_tests/1_core/data/test_enemy_def.gd": "11+",
    "7_tests/4_ui/editor/test_spawn_input.gd": "11+",
    "1_core/data/fx_def.gd": "12+",
    "1_core/editor/effect_preview.gd": "12+",
    "4_ui/editor/effect_input.gd": "12+",
    "4_ui/editor/effect_view.gd": "12+",
    "4_ui/editor/effect_panel.gd": "12+",
    "5_data/effets/etincelles.tres": "12+",
    "5_data/effets/fumee.tres": "12+",
    "5_data/effets/vapeur.tres": "12+",
    "7_tests/1_core/data/test_fx_def.gd": "12+",
    "7_tests/4_ui/editor/test_effect_input.gd": "12+",
    "1_core/editor/definition_editor.gd": "13+",
    "4_ui/editor/definition_panel.gd": "13+",
    "7_tests/1_core/editor/test_definition_editor.gd": "13+",
    "7_tests/4_ui/editor/test_definition_panel.gd": "13+",
    "1_core/data/animation_def.gd": "14+",
    "4_ui/editor/animation_panel.gd": "14+",
    "6_assets/exemple/modeles/bipede.tscn": "14+",
    "6_assets/exemple/modeles/volant.tscn": "14+",
    "5_data/animations/bombe.tres": "14+",
    "5_data/animations/brute.tres": "14+",
    "5_data/animations/cone.tres": "14+",
    "5_data/animations/melee.tres": "14+",
    "5_data/animations/racine.tres": "14+",
    "5_data/animations/tireur.tres": "14+",
    "5_data/animations/toupie.tres": "14+",
    "7_tests/1_core/data/test_animation_def.gd": "14+",
    "7_tests/4_ui/editor/test_animation_panel.gd": "14+",
}
