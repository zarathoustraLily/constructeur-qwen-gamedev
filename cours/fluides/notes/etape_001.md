# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Un fluide, sur un ordinateur, c'est d'abord une grille : une valeur par case, et plus tard une vitesse par case. Avant toute
physique, on pose ce champ, sa lecture entre deux cases, et le moyen de le voir.

Ce qu'on obtient : une tache claire à l'écran, calculée dans une grille de 64 × 64.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Le champ est dans `1_core/fluid/fluid_field.gd`, son image dans `1_core/fluid/fluid_image.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un tableau plat

`FluidField` range ses cases ligne par ligne dans un seul `PackedFloat32Array` : `index(x, y)` donne `y * width + x`. Un tableau
de tableaux créerait un objet par ligne ; un fluide lit des millions de cases par seconde. `put` pose une valeur, `at` la relit.
Hors de la grille, `at` rend la case du bord (`clampi`) : les calculs de voisinage n'ont pas de cas particulier au bord.

### 2. Lire entre deux cases

Le fluide transporte des valeurs à des positions qui ne tombent jamais pile sur une case. `sample(x, y)` mélange les quatre cases
autour du point, en deux `lerpf` le long de x puis un le long de y : c'est une lecture bilinéaire.

### 3. Compter et remplir

`total` additionne les cases : on s'en sert pour vérifier ce qu'un calcul conserve. `peak` rend le plus haut : on s'en sert pour
vérifier qu'un calcul n'invente rien. `copy_from` recopie sans créer de tableau. `add_disc` verse de la matière dans un disque,
le plus au centre et rien au rayon, sans sortir de la grille.

### 4. Voir le champ

`FluidImage.gray` change le champ en `Image`, en niveaux de gris : 0 est noir, `brightest` est blanc. Le champ ne sait rien de
l'écran : `2_sequence/main.gd` fait de cette image un `ImageTexture`, montré par un `TextureRect`.

## Ce qu'il faut retenir

Une grille plate, une lecture entre les cases, un moyen de voir et des mesures simples (total, plus haut) : tout le reste du cours se vérifie avec ça.
