# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** FLIP garde une grille à chaque pas. SPH s'en passe : le liquide n'est plus qu'un nuage de particules qui se sentent à distance. C'est simple, sans bord de grille, et parfait pour un jet, une flaque ou une fontaine.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Le liquide est dans `1_core/fluid/sph_solver.gd`, ses noyaux dans `1_core/fluid/sph_kernels.gd`, ses réglages dans `1_core/data/sph_settings.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Trois noyaux

Une particule pèse sur ce qui l'entoure, de moins en moins fort, jusqu'à sa portée `radius`. `SphKernels` donne trois formes :

- `density_weight` pour la densité. Il prend la distance au carré : il est appelé pour chaque paire, et une racine carrée en moins compte. Son intégrale sur le disque vaut 1 : c'est ce qui fait qu'une somme de masses donne une densité.
- `pressure_slope` pour la pression. Le noyau de densité a une pente nulle au contact : deux particules collées ne se repousseraient plus. Celui-ci, pointu, ne s'annule pas.
- `viscosity_curve` pour la viscosité. Il reste positif : il rapproche les vitesses sans jamais les écarter, ce qui évite une instabilité.

### 2. La grille de voisinage

Comparer chaque particule à toutes les autres coûte n². Mais une particule ne voit rien au-delà de `radius` : il suffit de ranger les particules dans des cases de ce côté, et de regarder les neuf cases autour.
`rebuild_neighbours` fait des listes chaînées dans deux tableaux : `_heads` donne la première particule d'une case, `_links` la suivante. Aucun objet créé, et ce schéma se transpose sur une carte à l'étape suivante.

`test_la_grille_trouve_les_memes_voisines_qu_une_recherche_complete` compare à la recherche naïve : c'est le juge de cette structure.

### 3. Densité et pression

`update_densities` additionne les masses voisines, pesées par la distance. La masse vient de l'écart de départ : `_mass = rest_density × spacing²`, ainsi un bloc posé à cet écart a sa densité de repos, à moins d'un cinquième près sur un noyau si court.

La pression est `stiffness × (densité - repos)`, jamais négative : une pression négative tirerait les particules les unes vers les autres, et elles s'agglutineraient en grumeaux.

### 4. Deux forces, opposées

`_force_between` calcule la force de `j` sur `i`. La formule partage la pression des deux particules : `(pᵢ + pⱼ) / (2 ρᵢ ρⱼ)`. Elle est symétrique : la force de `i` sur `j` est exactement l'opposée, et la quantité de mouvement
se conserve. La formule naïve, avec la seule pression de `i`, ne l'est pas : un liquide au repos se mettrait à dériver.

### 5. De petits pas

SPH est explicite : la pression agit au pas suivant. Un pas trop long fait exploser le liquide. `step` découpe donc un pas du jeu en `substeps` petits pas, et chacun refait tout, jusqu'à la grille de voisinage.

### 6. Les parois

`_integrate` fait rebondir une particule sur les parois, en gardant la part `bounce` de sa vitesse, puis la remet dans la cuve par `clamp`. Un rebond amorti laisse le liquide se calmer : avec un rebond entier, il ne perdrait rien contre les murs.

## Ce qu'il faut retenir

SPH, c'est une boucle : voisines, densité, pression, forces, déplacement. La symétrie des forces et la pression jamais négative sont les deux détails qui font la différence entre un liquide et une explosion.
