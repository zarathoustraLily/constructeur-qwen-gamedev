# Atelier · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Trois façons de faire moins de travail par image sans changer ce que le joueur voit :
chercher les voisins sans tout comparer, étaler un travail coûteux sur plusieurs images, et dessiner moins de
détails au loin.

Ce qu'on obtient : une grille spatiale qui rend exactement les mêmes voisins qu'une comparaison à tous, un
ordonnanceur qui sert mille objets à 64 par image, et des niveaux de détail qui ne clignotent pas sur leurs seuils.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Les outils sont dans `1_core/optimization/`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Une grille spatiale

Comparer chaque objet à tous les autres coûte n² : 300 objets, 90 000 comparaisons par image.
`1_core/optimization/spatial_grid.gd` range chaque objet dans sa case (`floori(position / côté)`, négatifs
compris) ; une recherche ne visite que les cases que le cercle touche, puis la vraie distance tranche. Le test
compare le résultat à la force brute sur 300 points tirés avec une graine : le même, à l'identique. Déplacer un
objet le retire de son ancienne case ; une case vide disparaît.

### 2. Une mise à jour échelonnée

`1_core/optimization/time_slicer.gd` sert au plus `budget` objets par image, à partir d'un curseur qui revient au
début : chaque objet est servi une fois par cycle de `ceil(n / budget)` images, et le coût par image reste borné.

### 3. Des niveaux de détail par distance

`1_core/optimization/distance_lod.gd` donne un niveau par seuil franchi. Un objet posé juste sur un seuil
changerait de niveau à chaque image : la marge (hystérésis) ne fait descendre en détail qu'un peu après le seuil et
remonter qu'un peu avant.
