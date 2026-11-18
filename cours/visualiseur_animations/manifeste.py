"""Ce que contient chaque projet d'étape du cours « visualiseur_animations ». Lu par usine/cours/jeu.py.

Demande de laurent du 2026-11-18 : « je voudrais que tu crées un cours qui permette de créer un visualiseur d'animation
des assets du jeu, les ennemis, les boss, les props, de visualiser sous tous les angles (quand ils sont en 3D) ou en
2D, donc les animations de l'ennemi comme du héros avec leur borderline noire, et d'en contrôler l'enchaînement des
animations avec la manette ou de les sélectionner une en particulier ou d'en enchaîner plusieurs par exemple avec des
cycles comme pause / début de course / course / fin de course / pause ou dash ou attaque ou coup reçu ; et comme je
sais que l'ombre joue un rôle dans ces animations et que les ennemis ou les props n'ont pas de contrôle manette
normalement, ça demande à créer un switch qui permette dans le visualiseur de le faire ».
Réponses du même jour : premier ennemi en « 3D Blender (.glb) » ; application finale « à côté de l'éditeur »
(PROJET_ROGUE_LIKE_002/VISUALISEUR_ANIMATIONS), le cours dans le dépôt pour les paires ; le plan en 12 étapes : « Oui,
lance ».

Le visualiseur est une application à part, comme l'éditeur de cartes : il lit les assets tels que Blender et
l'optimiseur d'atlas les écrivent, dans les dossiers de ses réglages (`5_data/visualiseur/config.json`, ou le
`config.json` posé à côté de l'exécutable exporté), sans les importer dans le projet.

Le jeu source (clé « visualiseur_animations » de [sources]) fournit GdUnit4 et les assets d'exemple, fabriqués par
`outils/fabriquer_exemple.py` (héros, golem, coffre en .glb ; flamme en atlas ; étincelle en images).
"""

GENRE = "jeu"
PREFIXE = "visualiseur"
SOURCE = "visualiseur_animations"
DERNIERE = 12

ETAPES = [
    {"piste": "Architecture + UI", "titre": "Le catalogue des assets : réglages en JSON, recherche dans les dossiers, liste par catégorie"},
    {"piste": "Graphisme 3D + Graphisme 2D", "titre": "Charger à l'exécution : modèles glTF, atlas de l'optimiseur, dossiers d'images, fichier d'accompagnement"},
    {"piste": "Graphisme 3D + Contrôle à la manette", "titre": "La caméra autour du sujet : vue libre, vue du jeu, clips faits pour un angle"},
    {"piste": "Shaders + Graphisme 3D", "titre": "Le contour noir : coque inversée d'épaisseur variable en 3D, contour tiré de la transparence en 2D"},
    {"piste": "Gameplay + UI", "titre": "La lecture : choisir une animation, pause, image par image, vitesse, boucle enregistrée"},
    {"piste": "Gameplay", "titre": "Les enchaînements : cycles écrits en données (pause, début de course, course, fin de course), transitions"},
    {"piste": "Contrôle à la manette + Gameplay", "titre": "Piloter le héros à la manette comme en jeu"},
    {"piste": "Contrôle à la manette + Architecture", "titre": "L'interrupteur « piloter » : jouer un ennemi, un boss ou un prop à la manette"},
    {"piste": "Shaders + Graphisme 3D", "titre": "L'ombre projetée : opacité uniforme, transitions entre lumières, contact avec les pieds"},
    {"piste": "Graphisme 3D + Architecture", "titre": "Les lumières de la carte : charger celles de l'éditeur de cartes, déplacer une lumière au stick"},
    {"piste": "Shaders + VFX", "titre": "Les teintes de zone sur l'asset, contour gardé noir"},
    {"piste": "Création de tests + Graphisme 3D", "titre": "Les captures sous plusieurs angles et à plusieurs instants"},
]

EXTENSIONS = {
    "addons/gdUnit4": "1+",
    # Les assets d'exemple, dans un dossier qui porte un `.gdignore` : Godot ne les importe pas, le visualiseur les lit
    # comme des fichiers, comme il lira ceux de Blender.
    "6_assets/exemple": "1+",
}

PRETES = [1, 2, 3]

FICHIERS = {
    "project.godot": "1+",
    "plan.md": "1+",
    "1_core/process_order.gd": "1+",
    "1_core/viewer/asset_source.gd": "1+",
    "1_core/viewer/json_values.gd": "1+",
    "1_core/viewer/viewer_config.gd": "1+",
    "1_core/viewer/asset_entry.gd": "1+",
    "1_core/viewer/asset_scanner.gd": "1+",
    "2_sequence/viewer/viewer_shell.gd": "1+",
    "2_sequence/viewer/viewer_shell.tscn": "1+",
    "4_ui/viewer/asset_list.gd": "1+",
    "5_data/visualiseur/config.json": "1+",
    "7_tests/lancer_tests.bat": "1+",
    "7_tests/1_core/test_documentation.gd": "1+",
    "7_tests/1_core/test_process_order.gd": "1+",
    "7_tests/1_core/viewer/test_viewer_config.gd": "1+",
    "7_tests/1_core/viewer/test_asset_scanner.gd": "1+",
    "7_tests/2_sequence/viewer/test_viewer_shell.gd": "1+",
    "1_core/viewer/loaded_model.gd": "2+",
    "1_core/viewer/model_loader.gd": "2+",
    "1_core/viewer/asset_sidecar.gd": "2+",
    "1_core/viewer/sprite_frame.gd": "2+",
    "1_core/viewer/sprite_animation.gd": "2+",
    "1_core/viewer/sprite_set.gd": "2+",
    "1_core/viewer/sprite_loader.gd": "2+",
    "2_sequence/viewer/viewer_stage.gd": "2+",
    "2_sequence/viewer/viewer_stage.tscn": "2+",
    "3_entities/subject/subject.gd": "2+",
    "3_entities/subject/model_view.gd": "2+",
    "3_entities/subject/sprite_view.gd": "2+",
    "4_ui/viewer/clip_list.gd": "2+",
    "7_tests/1_core/viewer/test_model_loader.gd": "2+",
    "7_tests/1_core/viewer/test_sprite_loader.gd": "2+",
    "7_tests/1_core/viewer/test_asset_sidecar.gd": "2+",
    "7_tests/3_entities/subject/test_model_view.gd": "2+",
    "7_tests/3_entities/subject/test_sprite_view.gd": "2+",
    "1_core/viewer/angle_clips.gd": "3+",
    "1_core/viewer/orbit_rig.gd": "3+",
    "4_ui/viewer/orbit_input.gd": "3+",
    "7_tests/1_core/viewer/test_angle_clips.gd": "3+",
    "7_tests/1_core/viewer/test_orbit_rig.gd": "3+",
    "7_tests/4_ui/viewer/test_orbit_input.gd": "3+",
}
