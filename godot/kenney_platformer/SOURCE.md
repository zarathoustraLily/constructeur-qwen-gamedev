# Source : Starter Kit 3D Platformer (Kenney)

- Dépôt : https://github.com/KenneyNL/Starter-Kit-3D-Platformer, commit `3fa8a04` (2026-03-12).
- Licence : code MIT (`LICENSE`) ; modèles, sprites et sons CC0.
- Moteur : déclaré pour Godot 4.6. Vérifié sous Godot 4.7.2.

## Retouches pour l'usine

- Retirés : `screenshots/`, `vector/` (sources d'art), les fichiers `.fbx`/`.fla`/`.log`.
- Tests GdUnit4 écrits pour l'usine dans `tests/` (29 tests : saut simple et double, gravité,
  pièces, déplacement selon la caméra, brique, plateforme qui tombe, nuage, HUD, caméra, sons).
- `scripts/player.gd` et `scripts/view.gd` : la caméra et la cible sont facultatives, pour que
  `player.tscn` se charge seule (juge `load_scene`). Dans `main.tscn`, elles sont toujours reliées.
