# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** L'étape 13 s'est arrêtée sur un mur : la divergence moyenne passait de 1,47 à 0,25, et plus rien, de 50 à 1 000 passes. La cause est dans la place des vitesses. On les déplace.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. La grille est dans `1_core/fluid/staggered_grid.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Chaque vitesse sur sa face

Jusqu'ici, tout vivait au centre des cases. `StaggeredGrid` y laisse la pression, et pose chaque vitesse sur la face qu'elle traverse : `u` sur les faces verticales, `v` sur les
faces horizontales. Une grille de 30 × 22 cases a donc 31 × 22 valeurs de `u` et 30 × 23 valeurs de `v`. C'est la grille de Harlow et Welch, dite MAC.

### 2. Une divergence à une case de distance

`divergence_at` lit les quatre faces de la case, sans le facteur 0,5 : ce qui sort, moins ce qui entre. C'est une définition plus directe : une vitesse sur une face passe vraiment d'une case à l'autre.

### 3. Une pression qui correspond

`_settled` vise la moyenne des voisines moins la divergence. Une case du bord a moins de voisines : on divise par celles qui existent, et un mur n'échange rien.
`subtract_gradient` retire à chaque face l'écart de pression entre ses deux cases.

Les trois formules lisent à une case de distance, et s'emboîtent exactement : la pente d'une pression, passée dans la divergence, redonne le calcul de `_settled`. C'est ce qui manquait à l'étape 13, où
la divergence lisait à deux cases et la pression à une.

### 4. La preuve

`test_la_projection_annule_la_divergence_sur_des_vagues_serrees` prend le pire cas de l'étape 13, les mêmes vagues serrées, et demande une divergence sous 0,001 dans toutes les cases.
`test_plus_de_passes_font_encore_baisser_la_divergence` vérifie ce qui ne marchait pas : ici, plus de passes servent à quelque chose.

### 5. Lire entre les faces

Comme `u` et `v` ne sont plus au même endroit, lire la vitesse en un point demande deux lectures décalées : `velocity_at` ajoute 0,5 en x pour `u`, 0,5 en y pour `v`. `transport` fait remonter le courant à
chaque face depuis sa propre place, et c'est l'erreur classique de cette grille : oublier ce décalage fait glisser tout le fluide d'une demi-case à chaque pas.

## Ce qu'il faut retenir

Une grille décalée coûte deux champs de tailles différentes et des lectures décalées. Elle rend une projection exacte. Les liquides en ont besoin : c'est la grille des deux étapes suivantes.
