"""Ce que contient chaque projet d'étape du cours « atelier ». Lu par usine/cours/jeu.py.

Demande de laurent du 2026-10-28 : « crée les paires manquantes qui soient EXTRÊMEMENT UTILES, codage de
l'interface aussi, de l'audio etc. », puis « contrôle manette aussi ». La création manquait au palier 1 (89 paires,
ETAT) : les cours du kart et du roguelike n'ont de tests que pour une partie de leurs fonctions. L'atelier est un
petit jeu construit étape par étape, un sujet de la grille par étape (décision 2), où chaque fonction documentée
(`##`) a des tests GdUnit4 qui la jugent : vidée, un test échoue ; écrite, ils passent. Écrit par Claude aux règles
du plan (godot/socle_jeu/AGENTS.md) et vérifié par Godot 4.7.2.

Le jeu source ne fournit que l'extension GdUnit4 (celui du kart, clé « kart » de [sources] dans config.toml) :
l'atelier n'a ni modèle ni texture ni son importés.
"""

GENRE = "jeu"
PREFIXE = "atelier"
SOURCE = "kart"
DERNIERE = 7

ETAPES = [
    {"piste": "Interface + Audio + Manette", "titre": "Le menu principal, les options de volume, la navigation à la manette"},
    {"piste": "Manette", "titre": "Zones mortes, vibrations et remappage des boutons"},
    {"piste": "Gameplay", "titre": "Santé, machine à états et mannequin d'entraînement"},
    {"piste": "Physique", "titre": "Le joueur : déplacement, gravité, saut, couches de collision"},
    {"piste": "Graphisme 3D", "titre": "La caméra qui suit et le cycle jour-nuit"},
    {"piste": "VFX", "titre": "Particules en code, tremblement de caméra, éclair d'un coup"},
    {"piste": "Procédural + VFX", "titre": "Les ondulations : une grille de maillage et une onde d'impact"},
]

EXTENSIONS = {
    "addons/gdUnit4": "1+",
}

PRETES = [1, 2, 3, 4, 5, 6, 7]

FICHIERS = {
    "project.godot": "1+",
    "0_autoload/audio_manager.gd": "1+",
    "1_core/audio/volume.gd": "1+",
    "1_core/data/menu_settings.gd": "1+",
    "2_sequence/main.gd": "1+",
    "2_sequence/main.tscn": "1+",
    "4_ui/menus/menu_focus.gd": "1+",
    "4_ui/menus/main_menu.gd": "1+",
    "4_ui/menus/main_menu.tscn": "1+",
    "4_ui/menus/options_menu.gd": "1+",
    "4_ui/menus/options_menu.tscn": "1+",
    "5_data/ui/menu_settings.tres": "1+",
    "7_tests/0_autoload/test_audio_manager.gd": "1+",
    "7_tests/1_core/audio/test_volume.gd": "1+",
    "7_tests/1_core/silence_audio.gd": "1+",
    "7_tests/1_core/test_documentation.gd": "1+",
    "7_tests/2_sequence/test_main.gd": "1+",
    "7_tests/4_ui/menus/test_main_menu.gd": "1+",
    "7_tests/4_ui/menus/test_menu_focus.gd": "1+",
    "7_tests/4_ui/menus/test_options_menu.gd": "1+",
    "7_tests/lancer_tests.bat": "1+",
    "1_core/data/gamepad_settings.gd": "2+",
    "1_core/input/action_remap.gd": "2+",
    "1_core/input/rumble.gd": "2+",
    "1_core/input/stick_filter.gd": "2+",
    "4_ui/menus/remap_menu.gd": "2+",
    "4_ui/menus/remap_menu.tscn": "2+",
    "5_data/input/gamepad_settings.tres": "2+",
    "7_tests/1_core/input/test_action_remap.gd": "2+",
    "7_tests/1_core/input/test_rumble.gd": "2+",
    "7_tests/1_core/input/test_stick_filter.gd": "2+",
    "7_tests/4_ui/menus/test_remap_menu.gd": "2+",
    "1_core/process_order.gd": "3+",
    "1_core/data/health_settings.gd": "3+",
    "1_core/data/dummy_settings.gd": "3+",
    "1_core/components/health_component.gd": "3+",
    "1_core/state_machine/state.gd": "3+",
    "1_core/state_machine/state_machine.gd": "3+",
    "3_entities/training_dummy/dummy_hit_state.gd": "3+",
    "3_entities/training_dummy/training_dummy.gd": "3+",
    "3_entities/training_dummy/training_dummy_view.gd": "3+",
    "3_entities/training_dummy/training_dummy.tscn": "3+",
    "5_data/gameplay/dummy_health.tres": "3+",
    "5_data/gameplay/dummy.tres": "3+",
    "7_tests/1_core/components/test_health_component.gd": "3+",
    "7_tests/1_core/state_machine/test_state_machine.gd": "3+",
    "7_tests/3_entities/training_dummy/test_training_dummy.gd": "3+",
    "1_core/data/move_settings.gd": "4+",
    "1_core/physics/motion.gd": "4+",
    "1_core/physics/layers.gd": "4+",
    "3_entities/player/player.gd": "4+",
    "3_entities/player/player_input.gd": "4+",
    "3_entities/player/player.tscn": "4+",
    "5_data/gameplay/player_move.tres": "4+",
    "7_tests/1_core/physics/test_motion.gd": "4+",
    "7_tests/1_core/physics/test_layers.gd": "4+",
    "7_tests/3_entities/player/test_player.gd": "4+",
    "1_core/data/camera_settings.gd": "5+",
    "1_core/data/day_settings.gd": "5+",
    "1_core/camera/follow_camera.gd": "5+",
    "1_core/camera/follow_camera.tscn": "5+",
    "1_core/lighting/day_cycle.gd": "5+",
    "5_data/camera/follow_camera.tres": "5+",
    "5_data/world/day.tres": "5+",
    "7_tests/1_core/camera/test_follow_camera.gd": "5+",
    "7_tests/1_core/lighting/test_day_cycle.gd": "5+",
    "1_core/data/vfx_settings.gd": "6+",
    "3_entities/effects/particle_recipes.gd": "6+",
    "3_entities/effects/camera_shake.gd": "6+",
    "3_entities/effects/hit_flash.gd": "6+",
    "5_data/vfx/vfx.tres": "6+",
    "7_tests/3_entities/effects/test_particle_recipes.gd": "6+",
    "7_tests/3_entities/effects/test_camera_shake.gd": "6+",
    "7_tests/3_entities/effects/test_hit_flash.gd": "6+",
    "1_core/data/ripple_settings.gd": "7+",
    "1_core/procedural/grid_mesh.gd": "7+",
    "1_core/procedural/ripple.gd": "7+",
    "3_entities/effects/ripple_surface.gd": "7+",
    "5_data/vfx/ripple.tres": "7+",
    "7_tests/1_core/procedural/test_grid_mesh.gd": "7+",
    "7_tests/1_core/procedural/test_ripple.gd": "7+",
    "7_tests/3_entities/effects/test_ripple_surface.gd": "7+",
}
