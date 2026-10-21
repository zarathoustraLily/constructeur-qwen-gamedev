"""Ce que contient chaque projet d'étape du cours « roguelike ». Lu par usine/cours/jeu.py.

Demande de laurent du 2026-10-20 : « tu fais exactement la même chose avec le jeu rogue like » que pour le kart
(un cours en étapes de création, pour que Qwen apprenne le contrôle à la manette, les effets visuels et les
shaders). Découpage en 14 étapes validé par laurent le 2026-10-21 (« Oui, vas-y »), avec trois choix :
- les cinq VisualShader du jeu deviennent du code .gdshader (« Oui, en .gdshader ») ;
- le jeu démarre sur le premier niveau de l'ordre tiré (« Oui, premier niveau tiré ») ;
- à la manette, on vise au stick droit, et stick au repos, vers où l'on marche (« Stick droit, sinon
  direction de marche »).
Le jeu source est le roguelike du cours GameDev.tv (« GDTV-Roguelike »), rangé selon le plan
(PROJET_ROGUE_LIKE_RANGE, clé « roguelike » de [sources] dans config.toml) : ses modèles KayKit, ses sons et
GdUnit4 y sont pris au moment de fabriquer, seulement ce que chaque étape désigne.
"""

GENRE = "jeu"
PREFIXE = "roguelike"
SOURCE = "roguelike"
DERNIERE = 14

ETAPES = [
    {"piste": "Contrôles", "titre": "Le projet et les contrôles : clavier, souris et manette"},
    {"piste": "Gameplay", "titre": "Le joueur : machine à états, course et chute"},
    {"piste": "Animation + Audio", "titre": "L'animation : arbre d'animation, pas, arme en main"},
    {"piste": "Monde", "titre": "Le niveau de test : GridMap, limite du monde, caméra"},
    {"piste": "Gameplay + Shader", "titre": "L'esquive : état, recharge, shader de traînée, son"},
    {"piste": "Gameplay + VFX", "titre": "Le combat : coups enchaînés, santé, recul, effet de lame"},
    {"piste": "IA + Shader", "titre": "Les ennemis au corps à corps : états, navigation, écho de défaite"},
    {"piste": "VFX + Shader", "titre": "Les ennemis à distance : boule de feu, impact, shader de feu"},
    {"piste": "Interface + VFX", "titre": "Le retour des coups : chiffres de dégâts, barre de santé, teinte rouge"},
    {"piste": "Gameplay + Données", "titre": "La vague : apparitions, courbe de difficulté, sortie"},
    {"piste": "Graphisme 3D", "titre": "Les trois niveaux : modèle commun, éclairage VoxelGI"},
    {"piste": "Architecture", "titre": "Le chef d'orchestre : GameFlow charge niveaux et boutique"},
    {"piste": "Interface + Shader", "titre": "La boutique d'améliorations"},
    {"piste": "Interface + Manette", "titre": "La pause et le remappage des contrôles"},
]

# Extensions copiées entières depuis le jeu source : GdUnit4 (les tests de chaque étape).
EXTENSIONS = {
    "addons/gdUnit4": "1+",
}

# Étapes écrites aux règles et vérifiées : seules elles sont fabriquées par défaut.
PRETES = [1, 2, 3, 4]

# Maîtres (cours/roguelike/maitres/<chemin>) et leur plage de présence.
FICHIERS = {
    "project.godot": "1+",
    "1_core/input/player_commands.gd": "1+",
    "1_core/input/rumble.gd": "1+",
    "3_entities/player/player_input.gd": "1+",
    "4_ui/hud/input_display/input_display.gd": "1+",
    "4_ui/hud/input_display/input_display.tscn": "1+",
    "2_sequence/main.gd": "1+",
    "2_sequence/main.tscn": "1+",
    "5_data/input/attack_rumble.tres": "1+",
    "7_tests/1_core/test_documentation.gd": "1+",
    "7_tests/2_sequence/test_main.gd": "1+",
    "7_tests/3_entities/player/test_player_input.gd": "1+",
    "7_tests/4_ui/hud/input_display/test_input_display.gd": "1+",
    "7_tests/lancer_tests.bat": "1+",
    "1_core/state_machine/state.gd": "2+",
    "1_core/state_machine/state_machine.gd": "2+",
    "1_core/characters/player_settings.gd": "2+",
    "5_data/player/player_settings.tres": "2+",
    "3_entities/player/player.gd": "2+",
    "3_entities/player/player.tscn": "2+",
    "3_entities/player/states/player_state.gd": "2+",
    "3_entities/player/states/player_run.gd": "2+",
    "3_entities/player/states/player_fall.gd": "2+",
    "7_tests/1_core/state_machine/etat_temoin.gd": "2+",
    "7_tests/1_core/state_machine/test_state_machine.gd": "2+",
    "7_tests/3_entities/player/test_player.gd": "2+",
    "1_core/animation/weapon_slot.gd": "3+",
    "1_core/animation/foot_bone.gd": "3+",
    "1_core/animation/animation_tree_view.gd": "3+",
    "3_entities/player/animated_player.tscn": "3+",
    "5_data/audio/default_bus_layout.tres": "3+",
    "1_core/zones/world_boundary.gd": "4+",
    "1_core/camera/shake_camera_3d.gd": "4+",
    "7_tests/1_core/zones/test_world_boundary.gd": "4+",
    "7_tests/1_core/camera/test_shake_camera_3d.gd": "4+",
}
