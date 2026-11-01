# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Un fluide sans obstacle n'a pas beaucoup d'intérêt : c'est en contournant qu'il tourbillonne.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Les murs sont dans `1_core/fluid/obstacle_mask.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Une case pleine ou libre

`ObstacleMask` garde un octet par case. `is_solid` compte tout ce qui est hors de la grille comme plein : le tour de la grille est
un mur fermé. `add_box` remplit un rectangle, `clear_inside` vide un champ dans les murs.

### 2. La projection voit les murs

`FluidProjection.divergence` prend une vitesse nulle pour les murs : rien n'en sort. `solve_pressure` les saute, et leur donne la pression
de la case qui les touche (`_seen`) : la pente y est nulle, donc rien ne les traverse. `subtract_gradient` fait de même.

### 3. Le solveur vide les murs

`FluidSolver._project` passe `walls` à ces trois fonctions, et vide la vitesse dans les murs (`clear_inside`) ; `_step_matter` y vide la matière.

### 4. Arrêter la vitesse contre un mur

Vitesse et pression vivent au centre des cases : tout près d'un mur, il reste une vitesse qui y entre. `stop_at_walls` l'arrête, et
laisse celle qui s'en éloigne. Un test l'a montré : dans une chambre fermée, un courant uniforme ne disparaît jamais tout à fait.

## Ce qu'il faut retenir

Un mur ne se traite pas à part : il change ce que la pression voit. Le contournement vient tout seul de la projection.
