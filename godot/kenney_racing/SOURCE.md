# Source : Starter Kit Racing (Kenney)

- Dépôt : https://github.com/KenneyNL/Starter-Kit-Racing, commit `2f2e5f2` (2026-08-21).
- Licence : code MIT (`LICENSE`) ; modèles, sprites et sons CC0.
- Moteur : déclaré pour Godot 4.6. Vérifié sous Godot 4.7.2.

## Retouches pour l'usine

- Retirés : `screenshots/`, `vector/` (sources d'art), les fichiers `.fbx`/`.fla`/`.log`, et
  `models/Library/mesh-library.tscn` (scène d'éditeur qui pointait vers un `track-ramp.glb`
  absent du dépôt ; le jeu utilise `mesh-library.tres`, intact).
- Tests GdUnit4 écrits pour l'usine dans `tests/` (22 tests : moteur, carrosserie, roues, traces,
  alignement au sol, choc, moto, caméra, et trois essais de conduite sur la piste).
