# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Jusqu'ici, de la fumée et une surface. Un vrai liquide a une surface libre, qui se déchire, se referme, éclabousse. Une grille seule n'y arrive pas : elle perd de l'eau à chaque pas. Il faut des particules.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`), et lancer `2_sequence/flip_tank.tscn`.
2. L'eau est dans `1_core/fluid/flip_solver.gd`, sa pression dans `1_core/fluid/staggered_grid.gd`, ses réglages dans `5_data/fluid/dam.tres`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Les particules portent l'eau

`FlipSolver` garde deux tableaux : `positions` et `velocities`. L'eau, ce sont elles : aucune particule ne se perd, donc la matière se conserve toute seule. Il leur manque ce que savait faire la grille : rester
incompressibles. On emprunte donc la grille décalée de l'étape 24, un instant, à chaque pas.

### 2. Déposer sur la grille

`_to_grid` dépose la vitesse des particules sur les faces. `_splat` répartit une valeur sur les quatre faces autour d'un point, selon la distance, et note ces poids ; `_average` divise ensuite par les poids : chaque
face reçoit la moyenne de ce qui l'entoure. `u` se lit décalée d'une demi-case en x, `v` en y : `_to_grid` ajoute 0,5 au bon axe, exactement comme `velocity_at`.

### 3. Une surface libre

`_mark_water` note les cases qui contiennent une particule. C'est ce qui change tout pour la pression. Dans `solve_water_pressure`, seules ces cases sont calculées, et `_settled_in_water` distingue deux bords :
**l'air compte pour une pression nulle**, parce qu'il ne pousse pas, et **un mur ne compte pas**, parce qu'il n'échange rien. Confondre les deux donne une eau qui colle au vide ou qui traverse le sol.

### 4. PIC et FLIP

Après la pression, il faut rendre la vitesse aux particules. Deux idées :

- **PIC** : la particule reprend la vitesse de la grille. C'est stable, mais chaque aller-retour fait une moyenne : tout s'amortit, et l'eau devient du miel.
- **FLIP** : la particule garde sa vitesse et n'ajoute que ce qui a changé sur la grille (`now - before`). Rien ne s'amortit, mais le bruit reste.

`_to_particles` mélange les deux par `flip_ratio`. D'où les copies `_before_u` et `_before_v`, faites avant la gravité et la pression : sans elles, on ne saurait pas ce qui a changé.

### 5. Bouger

`_move` déplace les particules dans le courant de la grille, en lisant la vitesse à mi-chemin : c'est plus juste, surtout dans les tourbillons. La vitesse propre de la particule ne sert qu'au pas suivant.
`clamp` les garde dans la cuve.

### 6. Les tests d'un système chaotique

Une éclaboussure ne se compare à rien. On teste donc ce qui doit rester vrai : personne ne sort, un barrage s'étale, une eau au repos reste presque au repos, et FLIP garde plus de mouvement que PIC. Chaque étape
intérieure, elle, a son test exact : la vitesse déposée, la moyenne de deux particules, l'aller-retour d'une vitesse uniforme.

## Ce qu'il faut retenir

Particules pour la matière, grille pour la pression. La surface libre tient dans une ligne : l'air vaut zéro, un mur ne compte pas.
