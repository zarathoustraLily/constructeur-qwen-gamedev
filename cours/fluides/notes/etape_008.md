# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La grille arrondit : les petits tourbillons disparaissent, et la fumée devient molle. Le confinement les rend, et c'est ce
qui donne ces volutes qui s'enroulent.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Le calcul est dans `1_core/fluid/vorticity.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Mesurer la rotation

`Vorticity.curl` donne la rotation de la vitesse dans chaque case : une rotation d'ensemble à la vitesse angulaire w vaut 2w, un
courant uniforme vaut 0. Le signe dit le sens.

### 2. Pousser vers le centre de la rotation

`Vorticity.confine` cherche, dans chaque case, la direction où la rotation grandit (`toward`). Elle pousse à angle droit de cette
direction, selon la rotation de la case : cela resserre le tourbillon. Le pas `strength * delta` reste en jetons de vitesse.

### 3. Dans le solveur

`FluidSolver._step_velocity` applique le confinement au début du pas, si `vortex_strength` n'est pas nul. Trop fort, le fluide
devient nerveux : c'est un réglage, à juger sur l'image.

## Ce qu'il faut retenir

On ne simule pas ce que la grille ne peut pas tenir : on le rend. La force se calcule sur la rotation déjà là.
