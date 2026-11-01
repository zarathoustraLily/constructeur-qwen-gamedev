"""Ce que contient chaque projet d'étape du cours « fluides ». Lu par usine/cours/jeu.py.

Demande de laurent du 2026-11-01 : « c'esr qunad meme super important.. le fluide aucun autre projet ne le travaille ! donc oui
fait un maximum de paires sur le sujet que qwen apprennen a code des fluide sous godot ». Le simulateur du cours du boss est en
Python, hors de Godot : ce cours refait le chemin dans Godot, du champ sur une grille au feu, chaque fonction documentée ayant
des tests GdUnit4 qui la jugent, pour que toutes les familles de paires puissent s'en servir. Écrit par Claude aux règles du
plan (godot/socle_jeu/AGENTS.md) et vérifié par Godot 4.7.2.

Le jeu source ne fournit que l'extension GdUnit4 (celui du kart, clé « kart » de [sources] dans config.toml).
"""

GENRE = "jeu"
PREFIXE = "fluides"
SOURCE = "kart"
DERNIERE = 13

ETAPES = [
    {"piste": "Procédural", "titre": "Le champ : une valeur par case, et son image"},
    {"piste": "Procédural + Physique", "titre": "Le transport : remonter le courant pour rester stable"},
    {"piste": "Physique", "titre": "La diffusion : étaler sans exploser"},
    {"piste": "Physique", "titre": "La pression : un fluide ne s'entasse pas"},
    {"piste": "Physique + VFX", "titre": "Le solveur : de la fumée qui coule"},
    {"piste": "Physique", "titre": "Les murs : le fluide contourne"},
    {"piste": "VFX + Physique", "titre": "MacCormack : un transport plus net"},
    {"piste": "VFX + Physique", "titre": "Les tourbillons : rendre ce que la grille efface"},
    {"piste": "VFX + Physique", "titre": "Le feu : carburant, chaleur, suie et dilatation"},
    {"piste": "VFX + Gameplay", "titre": "Un feu en jeu : couleurs, souris, cadence"},
    {"piste": "Shader de calcul + Optimisation", "titre": "Le premier shader de calcul : la carte multiplie un tampon"},
    {"piste": "Shader de calcul + Physique", "titre": "Le transport sur la carte : des images, et le processeur pour juge"},
    {"piste": "Shader de calcul + Physique", "titre": "La pression sur la carte : le damier rouge-noir en parallèle"},
]

EXTENSIONS = {
    "addons/gdUnit4": "1+",
}

PRETES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]

FICHIERS = {
    "project.godot": "1+",
    "2_sequence/main.gd": "1+",
    "2_sequence/main.tscn": "1+",
    "1_core/fluid/fluid_field.gd": "1+",
    "1_core/fluid/fluid_image.gd": "1+",
    "7_tests/lancer_tests.bat": "1+",
    "7_tests/1_core/fluid/test_fluid_field.gd": "1+",
    "7_tests/1_core/fluid/test_fluid_image.gd": "1+",
    "7_tests/2_sequence/test_main.gd": "1+",
    "1_core/fluid/advection.gd": "2+",
    "7_tests/1_core/fluid/test_advection.gd": "2+",
    "1_core/fluid/diffusion.gd": "3+",
    "7_tests/1_core/fluid/test_diffusion.gd": "3+",
    "1_core/fluid/fluid_projection.gd": "4+",
    "7_tests/1_core/fluid/test_fluid_projection.gd": "4+",
    "1_core/data/fluid_settings.gd": "5+",
    "1_core/fluid/fluid_solver.gd": "5+",
    "5_data/fluid/smoke.tres": "5+",
    "7_tests/1_core/fluid/test_fluid_solver.gd": "5+",
    "1_core/fluid/obstacle_mask.gd": "6+",
    "7_tests/1_core/fluid/test_obstacle_mask.gd": "6+",
    "1_core/fluid/vorticity.gd": "8+",
    "7_tests/1_core/fluid/test_vorticity.gd": "8+",
    "1_core/data/fire_settings.gd": "9+",
    "1_core/fluid/combustion.gd": "9+",
    "7_tests/1_core/fluid/test_combustion.gd": "9+",
    "5_data/fluid/flame.tres": "10+",
    "5_data/fluid/fire.tres": "10+",
    "1_core/gpu/compute_device.gd": "11+",
    "1_core/gpu/compute_pass.gd": "11+",
    "1_core/gpu/shaders/scale_values.glsl": "11+",
    "7_tests/check_shaders.gd": "11+",
    "7_tests/1_core/gpu/test_compute_device.gd": "11+",
    "7_tests/1_core/gpu/test_compute_pass.gd": "11+",
    "1_core/gpu/gpu_advection.gd": "12+",
    "1_core/gpu/shaders/advect.glsl": "12+",
    "1_core/gpu/shaders/mac_cormack.glsl": "12+",
    "7_tests/1_core/gpu/grid_check.gd": "12+",
    "7_tests/1_core/gpu/test_gpu_advection.gd": "12+",
    "1_core/gpu/gpu_projection.gd": "13+",
    "1_core/gpu/shaders/divergence.glsl": "13+",
    "1_core/gpu/shaders/pressure.glsl": "13+",
    "1_core/gpu/shaders/subtract_gradient.glsl": "13+",
    "7_tests/1_core/gpu/test_gpu_projection.gd": "13+",
}
