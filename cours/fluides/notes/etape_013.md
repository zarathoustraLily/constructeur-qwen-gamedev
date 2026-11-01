# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La pression est la passe la plus chère d'un fluide. Le damier rouge-noir de l'étape 4 prend ici tout son sens : toutes les cases d'une couleur se calculent en même temps.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Les shaders sont `divergence.glsl`, `pressure.glsl` et `subtract_gradient.glsl` dans `1_core/gpu/shaders/`, leur appel `1_core/gpu/gpu_projection.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Les murs en image

`ComputeDevice.new_mask` crée une texture `DATA_FORMAT_R8_UNORM` : un octet par case suffit, et `ObstacleMask.solid` a déjà cette forme.
Un format `UNORM` lit l'octet divisé par 255 : la valeur 1 de `solid` se lit 0,0039. Le test du shader est donc `> 0.0`, pas `> 0.5`.

`is_solid` compte tout ce qui est hors de la grille pour un mur, comme `ObstacleMask.is_solid`.

### 2. La divergence

`divergence.glsl` lit les quatre voisines et compte un mur pour une vitesse nulle (`x_at`, `y_at`). Elle écrit dans une autre image que celles qu'elle lit.

### 3. Une seule image, lue et écrite

`pressure.glsl` lit et écrit `pressure` : l'image est déclarée sans `readonly` ni `writeonly`. C'est sans danger parce qu'une case d'une couleur ne
lit que des cases de l'autre : `(cell.x + cell.y + color) & 1` écarte l'autre moitié, et aucune invocation ne lit ce qu'une autre écrit. Le
résultat ne dépend donc pas de l'ordre, et il est le même que sur le processeur.

`GpuProjection.solve_pressure` lance deux passes par itération, une par couleur. La couleur passe en constante, comme un flottant que le
shader convertit par `int()` : `run` n'envoie que des flottants.

### 4. La pente

`subtract_gradient.glsl` lit la vitesse et l'écrit sur place, case par case : chaque invocation ne touche que sa propre case.

### 5. Ce que la projection ne fait pas

On attendait une divergence nulle. Mesuré sur la grille de test, au processeur, dont la carte rend les valeurs : la divergence moyenne passe de 1,47 à
0,25, et ne descend plus. Elle vaut 0,2479 après 50 passes, 0,2477 après 200 et après 1 000. Ce n'est donc pas un manque de passes.

La cause est dans les formules. La divergence et la pente lisent les voisines à deux cases de distance, la pression à une seule. Vitesse et pression
vivent au même endroit, et leurs formules ne s'annulent exactement que pour les formes lisses : les hautes fréquences restent. La grille
de test est faite de vagues très serrées, le pire cas. C'est pourquoi `test_la_projection_divise_la_divergence` demande un rapport de 5 et non zéro.

## Ce qu'il faut retenir

Un calcul parallèle demande que personne ne lise ce qu'un autre écrit : le damier le garantit. Quand un résultat s'arrête de progresser, ce n'est plus
un problème de nombre de passes : il faut regarder la méthode.
