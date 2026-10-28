# Atelier · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Trois décors construits entièrement en code, chacun tiré d'une graine : le même résultat à
chaque ouverture, un autre en changeant la graine.

Ce qu'on obtient : un arbre (tronc, branches, feuilles), un champ de nuages au-dessus de la scène, et une galaxie
spirale de 4 000 étoiles, dessinés en quelques appels de dessin grâce aux `MultiMesh`.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Ouvrir `6_assets/Mesh/Procedural/NATURE/tree.tscn`, `clouds.tscn` ou `galaxy.tscn` : les générateurs sont
   `@tool`, ils se construisent dans l'éditeur ; changer un réglage du `.tres` les reconstruit.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un arbre récursif

`1_core/procedural/tree_builder.gd` part d'un tronc vertical et, à chaque niveau, fait pousser des branches filles
au bout de leur parent : plus courtes (`length_ratio`), plus fines (`radius_ratio`), penchées d'un angle et
réparties en tour autour de lui (`child_direction` : `Vector3.rotated` autour d'un axe de côté, puis autour du
parent). Un `RandomNumberGenerator` à graine fixe ajoute un peu de variation. Avec k filles par branche et p
niveaux, l'arbre a 1 + k + … + k^p branches. Chaque branche devient un prisme à quatre faces (`SurfaceTool`), et
des feuilles se posent autour du bout de chaque rameau.

### 2. Répartir au hasard, avec une graine

`1_core/procedural/scatter.gd` tire des points uniformes dans un disque : le rayon est la racine d'un tirage
uniforme, sans quoi les points s'entasseraient au centre (le disque de rayon R/√2 a la moitié de l'aire). Il
construit aussi le `MultiMesh` : une transformation (et au besoin une couleur) par copie, `instance_count` copies
d'un même maillage en un seul appel de dessin.

### 3. Une galaxie spirale

`1_core/procedural/galaxy.gd` met chaque étoile sur un bras (à intervalles égaux), à une distance tirée plus
souvent près du centre, puis enroule l'angle du bras avec la distance (une spirale) et écarte l'étoile de son bras
(`randfn`, une loi normale). Sa couleur va du cœur chaud au bord froid ; `use_colors` du `MultiMesh` et
`vertex_color_use_as_albedo` du matériau la montrent.

### 4. Des générateurs @tool

`6_assets/Mesh/Procedural/NATURE/` : chaque générateur se reconstruit à l'ouverture et quand on change ses
réglages (un `set` sur la propriété exportée), sans laisser l'ancien résultat derrière lui. Leurs réglages sont des
`.tres` de `5_data/DECORS/NATURE/`.
