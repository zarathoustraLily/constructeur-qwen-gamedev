"""Ce que contient chaque projet d'étape du cours « boss_action_rpg ». Lu par usine/cours/jeu.py.

Demande de laurent du 2026-10-28 : « tu crées un niveau de jeu professionnel avec un rendu professionnel avec Godot
4.7, d'un niveau de BOSS action RPG à la DARK SOULS ! le rendu et la finalisation d'un code propre et extrêmement
optimisé et performant en 3D ! » ; « le héros doit tirer sur le golem » ; « change d'échelle le saloon pour qu'il soit
plus dramatique ». Le cours enseigne à Qwen comment on part de ce prompt pour arriver au jeu : chaque note d'étape
explique la démarche (ce qu'on cherche, pourquoi, comment on vérifie). Combat original du genre (conception :
`D:\\GODOT\\PROJETS_DEMOS\\PROJET_BOSS_ACTION_RPG\\SUIVIS_PROGRESSION\\conception.md`).

Le jeu source : le dossier du jeu lui-même (clé « boss_action_rpg » de [sources]) : il fournit l'extension GdUnit4
et, à partir de l'étape 7, les modèles, textures et animations classés dans `6_assets/` (tirés des paquets de laurent
par les outils de `SUIVIS_PROGRESSION/outils/`). Jusqu'à l'étape 6, c'était le jeu du kart (pour GdUnit4 seulement).
"""

GENRE = "jeu"
PREFIXE = "boss"
SOURCE = "boss_action_rpg"
DERNIERE = 10

ETAPES = [
    {"piste": "Architecture + Contrôles", "titre": "Le socle : nomenclature, réglages stricts, actions, ordre d'exécution"},
    {"piste": "Gameplay + Physique", "titre": "Le héros en maquette grise : courir par rapport à la caméra"},
    {"piste": "Graphisme 3D + Contrôles", "titre": "La caméra à la troisième personne et le verrouillage de cible"},
    {"piste": "Gameplay + Contrôles", "titre": "L'endurance et la roulade à invincibilité : la machine à états du héros"},
    {"piste": "Gameplay + Physique + Optimisation", "titre": "Le tir : visée au centre de l'écran, projectiles en réserve, surchauffe"},
    {"piste": "Gameplay + Architecture", "titre": "La santé du héros : coups reçus, fioles, chute et recommencement"},
    {"piste": "Graphisme 3D + Optimisation", "titre": "Le saloon d'un géant et son gardien : décor et boss tirés de paquets Unity, ambiance"},
    {"piste": "Graphisme 3D + Gameplay", "titre": "Le héros animé : un soldat reciblé, son arbre d'animation branché sur ses états"},
    {"piste": "UI + Architecture", "titre": "L'interface du genre : jauges à traîne, fioles, barre du boss, écran de chute"},
    {"piste": "VFX + Shaders", "titre": "La carboglace : une brume au sol en volutes, par un shader de brouillard"},
]

EXTENSIONS = {
    "addons/gdUnit4": "1+",
}

PRETES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

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
    "1_core/data/camera_settings.gd": "3+",
    "1_core/camera/lock_on.gd": "3+",
    "1_core/camera/orbit_camera.gd": "3+",
    "1_core/camera/camera_input.gd": "3+",
    "1_core/camera/orbit_camera.tscn": "3+",
    "5_data/camera/camera_settings.tres": "3+",
    "7_tests/1_core/camera/test_lock_on.gd": "3+",
    "7_tests/1_core/camera/test_orbit_camera.gd": "3+",
    "1_core/state_machine/state.gd": "4+",
    "1_core/state_machine/state_machine.gd": "4+",
    "1_core/input/input_buffer.gd": "4+",
    "1_core/data/stamina_settings.gd": "4+",
    "1_core/components/stamina_component.gd": "4+",
    "5_data/hero/hero_stamina.tres": "4+",
    "3_entities/hero/states/hero_move_state.gd": "4+",
    "3_entities/hero/states/hero_roll_state.gd": "4+",
    "7_tests/1_core/state_machine/test_state_machine.gd": "4+",
    "7_tests/1_core/input/test_input_buffer.gd": "4+",
    "7_tests/1_core/components/test_stamina_component.gd": "4+",
    "1_core/data/health_settings.gd": "5+",
    "1_core/components/health_component.gd": "5+",
    "5_data/target/target_health.tres": "5-6",
    "1_core/data/heat_settings.gd": "5+",
    "1_core/components/heat_component.gd": "5+",
    "5_data/hero/hero_gun_heat.tres": "5+",
    "1_core/data/gun_settings.gd": "5+",
    "5_data/hero/hero_gun.tres": "5+",
    "1_core/combat/hurtbox.gd": "5+",
    "1_core/combat/projectile.gd": "5+",
    "1_core/combat/projectile.tscn": "5+",
    "1_core/combat/projectile_pool.gd": "5+",
    "1_core/combat/aim.gd": "5+",
    "3_entities/hero/hero_gun.gd": "5+",
    "7_tests/1_core/components/test_health_component.gd": "5+",
    "7_tests/1_core/components/test_heat_component.gd": "5+",
    "7_tests/1_core/combat/test_hurtbox.gd": "5+",
    "7_tests/1_core/combat/test_projectile.gd": "5+",
    "7_tests/1_core/combat/test_aim.gd": "5+",
    "7_tests/3_entities/hero/test_hero_gun.gd": "5+",
    "1_core/combat/hitbox.gd": "6+",
    "1_core/components/flask_component.gd": "6+",
    "5_data/hero/hero_health.tres": "6+",
    "1_core/data/encounter_settings.gd": "6+",
    "5_data/encounter/encounter.tres": "6+",
    "3_entities/hero/states/hero_hit_state.gd": "6+",
    "3_entities/hero/states/hero_heal_state.gd": "6+",
    "3_entities/hero/states/hero_dead_state.gd": "6+",
    "7_tests/1_core/combat/test_hitbox.gd": "6+",
    "7_tests/1_core/components/test_flask_component.gd": "6+",
    "5_data/environment/arena_environment.tres": "7+",
    "5_data/environment/ground_mist.tres": "7-9",
    "5_data/boss/golem_health.tres": "7+",
    "3_entities/boss/golem.gd": "7+",
    "3_entities/boss/golem.tscn": "7+",
    "7_tests/3_entities/boss/test_golem.gd": "7+",
    "1_core/data/hero_view_settings.gd": "8+",
    "5_data/hero/hero_view.tres": "8+",
    "3_entities/hero/hero_view.gd": "8+",
    "7_tests/3_entities/hero/test_hero_view.gd": "8+",
    "1_core/data/hud_settings.gd": "9+",
    "5_data/ui/hud.tres": "9+",
    "4_ui/hud/hud.gd": "9+",
    "4_ui/hud/hud.tscn": "9+",
    "4_ui/hud/stat_bar/stat_bar.gd": "9+",
    "4_ui/hud/flask_counter/flask_counter.gd": "9+",
    "4_ui/hud/flask_counter/flask_counter.tscn": "9+",
    "4_ui/hud/boss_bar/boss_bar.gd": "9+",
    "4_ui/hud/boss_bar/boss_bar.tscn": "9+",
    "4_ui/overlays/defeat_screen/defeat_screen.gd": "9+",
    "4_ui/overlays/defeat_screen/defeat_screen.tscn": "9+",
    "7_tests/4_ui/hud/test_hud.gd": "9+",
    "7_tests/4_ui/hud/stat_bar/test_stat_bar.gd": "9+",
    "7_tests/4_ui/hud/flask_counter/test_flask_counter.gd": "9+",
    "7_tests/4_ui/hud/boss_bar/test_boss_bar.gd": "9+",
    "7_tests/4_ui/overlays/defeat_screen/test_defeat_screen.gd": "9+",
    "6_assets/Shader/Environment/ground_mist.gdshader": "10+",
    "5_data/environment/dry_ice_mist.tres": "10+",
}
