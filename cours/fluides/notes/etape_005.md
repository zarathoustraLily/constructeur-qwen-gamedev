# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Toutes les pièces sont là : on les assemble dans l'ordre, et la fumée coule.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Le solveur est dans `1_core/fluid/fluid_solver.gd`, ses réglages dans `5_data/fluid/smoke.tres`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Les réglages sont des données

`FluidSettings` porte la taille de la grille, la viscosité, le nombre de passes, la surrelaxation, la perte de matière.
`smoke.tres` les fixe : changer de fumée ne touche pas au code.

### 2. Un champ et son double

`FluidSolver` garde chaque champ avec un double de travail : le transport lit l'un et écrit l'autre, puis on échange les
références (`_swap_velocity`). Aucun tableau n'est créé pendant un pas : le test compte les objets.

### 3. L'ordre d'un pas

`_step_velocity` diffuse si le fluide est épais, projette, transporte la vitesse par elle-même, projette de nouveau : le transport
abîme l'absence de divergence. `_step_matter` transporte ensuite la matière par cette vitesse, puis en perd un peu (`exp`, pour ne
pas dépendre de la cadence). `step` enchaîne les deux. `add_force` pousse le fluide dans un disque.

### 4. La scène

`2_sequence/main.gd` verse de la matière et pousse vers le haut à chaque image de physique, puis montre l'image. Un glissé de la
souris pousse le fluide (`_unhandled_input`).

## Ce qu'il faut retenir

Projeter, transporter, projeter : la vitesse d'abord, la matière ensuite. Un pas ne crée rien.
