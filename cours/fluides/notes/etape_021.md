# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Jusqu'ici, le fluide remplissait une grille. L'eau d'un lac n'a pas besoin de ça : seule sa surface se voit. Une hauteur par case suffit, et l'équation des ondes donne les ronds dans l'eau pour trois fois rien.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Lancer le projet : la scène principale est maintenant `2_sequence/gpu_waves.tscn`. Il pleut, et un clic pose une goutte. L'équation est dans `1_core/fluid/wave_solver.gd`, et sur la carte dans `1_core/gpu/gpu_waves.gd` et `1_core/gpu/shaders/wave.glsl`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. L'équation des ondes

Une case accélère vers la moyenne de ses voisines. Une accélération demande deux états : la vitesse d'une case est l'écart entre sa hauteur et sa hauteur d'avant. Un pas s'écrit donc :

`nouvelle = ici + (ici - avant) * amortissement + courant² * (somme des quatre voisines - 4 * ici)`

Il n'y a aucune inconnue à résoudre, donc aucune passe de pression : une lecture de cinq cases par pas. C'est ce qui rend cette eau si peu chère.

### 2. La limite de Courant

Le nombre de Courant est le chemin, en cases, qu'une onde fait en un pas. Une case ne parle qu'à ses voisines : si l'onde va plus vite que l'information, le schéma explose. En deux dimensions, la limite est 1 / √2. `MAX_COURANT` la prend un peu en dessous.

Un jeu ne choisit pas son pas de temps. `substeps` découpe donc le pas demandé en autant de petits pas qu'il faut. `test_un_grand_pas_n_explose_pas` avance d'une demi-seconde d'un coup.

### 3. Une goutte qui ne crée pas d'eau

Si une goutte ne s'ajoute qu'à la surface, l'écart avec la surface d'avant lui donne une vitesse, et l'eau monte toute seule à chaque pas. `drop` l'ajoute aux deux : la bosse part immobile. Le schéma garde alors la somme des hauteurs, à chaque pas : `test_une_onde_ne_cree_pas_d_eau`.

### 4. Le bord

`clamp` lit la case du bord à la place d'une case qui n'existe pas : la pente y est nulle, et l'onde repart. Sans rien de plus, on a un bassin. La carte fait le même calcul.

### 5. Le processeur pour juge

`WaveSolver` a le même pas que `wave.glsl`. Les suites comparent les deux surfaces, case par case, jusqu'à 0,0005 près, y compris près d'un coin. `GpuWaves` a trois textures : on écrit la nouvelle à partir des deux dernières, et elles tournent à chaque pas. Il ne faut pas écrire dans une texture qu'on lit : la case voisine lirait déjà le pas suivant.

### 6. Le plan soulevé

`vertex()` lit la texture pour soulever les sommets. Mais un plan de 160 mailles ne donne pas la finesse de 256 cases : la pente se calcule donc dans `fragment()`, pixel par pixel, à partir de quatre lectures. C'est elle qui fait le reflet.

`NORMAL` s'écrit dans le repère de la caméra : la pente passe par `VIEW_MATRIX`.

### 7. Le clic

`Plane.PLANE_XZ.intersects_ray` donne le point du plan sous la souris, et `cell_of` le change en case. Comme `gpu_fire.gd`, `gpu_waves.gd` passe par le fil du rendu pour tout ce qui touche à la carte.

## Ce qu'il faut retenir

Quand seule la surface se voit, on ne simule que la surface. Une équation sans inconnue n'a besoin que d'un pas assez petit : c'est la limite de Courant.
