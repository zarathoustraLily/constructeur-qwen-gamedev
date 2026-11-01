# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Une image cuite garde la lumière de la cuisson : éclairée de gauche à la cuisson, la fumée le reste en jeu, même au pied d'une torche à droite. On cuit donc six réponses, une par direction, et on les mêle en jeu. C'est le « six-way lighting ».

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Lancer le projet : la scène principale est maintenant `2_sequence/six_way_puff.tscn`, et la lumière tourne autour de la fumée. La cuisson est dans `1_core/gpu/six_way_baker.gd`, le mélange dans `1_core/fluid/six_way.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Ce qu'une case renvoie

Pour chaque pixel, `six_way.glsl` descend la colonne depuis la caméra. Une case compte d'autant que le regard arrive jusqu'à elle (`passing`), et d'autant que la lumière lui parvient (`light_from`). `light_from` marche case après case vers le bord, en additionnant la fumée. C'est une boucle dans une boucle dans une boucle : sur la carte, pour une cuisson, on peut se le permettre. Pas à chaque image.

Comme à l'étape 18, `if (matter <= 0.0)` saute le vide, et c'est là qu'est le gain.

### 2. Six canaux dans deux images

Une texture a quatre canaux. Les six réponses tiennent dans deux images : droite, haut, arrière dans la première ; gauche, bas, avant dans la seconde. Le dernier canal garde l'opacité. `new_color_texture` crée une image `R32G32B32A32_SFLOAT`, et `Image.FORMAT_RGBAF` en a le même rangement.

### 3. Un juge pour la lumière

Sur une boule, on ne sait pas calculer la réponse à la main. Sur un volume uniforme, si. Appelons `q` ce qui reste de la lumière après une case, et `N` le nombre de cases :

- de face, la lumière et le regard font le même trajet : la somme des `(1 - q) q^(2k)` ;
- de dos, lumière et regard se partagent toute la colonne : `N (1 - q) q^(N-1)` ;
- de côté, la lumière perd ce qui sépare le pixel du bord, quelle que soit la profondeur.

Les trois sont des tests. Ces calculs supposent qu'une case ne se cache pas elle-même : c'est le rôle du `cell + direction` au départ de la marche.

Une boule donne deux autres règles : le côté éclairé est du côté de la lumière, et droite et gauche sont le miroir l'une de l'autre.

### 4. Mêler en jeu

`light()` tourne une fois par lumière. Sur un plan tourné vers la caméra, les axes du plan sont ceux de `LIGHT` : x à droite, y en haut, z vers la caméra. Chaque axe prend l'image de son côté, et le signe de `LIGHT.z` choisit entre l'avant et l'arrière.

Les poids sont les carrés de `LIGHT`. Comme `LIGHT` a pour longueur 1, leur somme fait 1 : une fumée égale partout ne change pas d'éclat quand la lumière tourne. Avec les valeurs absolues, elle s'éclaircirait entre deux axes. `test_une_fumee_egale_partout_ne_depend_pas_de_la_direction` le garde.

`first_seen` et `second_seen` sont des `varying` écrits dans `fragment()` : c'est ainsi que `light()` reçoit ce que `fragment()` a lu.

### 5. Le mélange prémultiplié

Les images cuites contiennent déjà l'opacité : ce qu'une case renvoie compte d'autant que le regard l'atteint. Les multiplier encore par l'alpha assombrirait les bords, d'où `blend_premul_alpha`. `ambient_light_disabled` : ici, toute la lumière vient des six images.

## Ce qu'il faut retenir

On n'a pas cuit une image, mais une réponse à la lumière. Pour un volume uniforme, la réponse se calcule : c'est le juge qu'il fallait.
