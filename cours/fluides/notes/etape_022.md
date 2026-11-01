# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Les vagues de l'étape précédente oscillent sur place : l'eau ne va nulle part. Pour une crue, une rivière ou une flaque qui coule, il faut que l'eau se déplace pour de bon, et qu'elle épouse le sol. Là encore, une profondeur par case suffit.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Lancer le projet : la scène principale est maintenant `2_sequence/gpu_flood.tscn`. Une source coule sur un relief, et un glissé de la souris verse de l'eau. L'eau est dans `1_core/fluid/flood_solver.gd`, et sur la carte dans `1_core/gpu/gpu_flood.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Des tuyaux entre les cases

On imagine un tuyau entre chaque paire de cases voisines. L'écart des niveaux pousse l'eau, et le débit a de l'élan : il garde sa vitesse d'un pas à l'autre. C'est la méthode des tuyaux virtuels. Une case tient quatre débits sortants : vers la droite, la gauche, le bas, le haut.

Un tuyau ne coule que dans un sens : `max(0.0, …)`. Le débit inverse est celui de la voisine.

### 2. L'eau suit son niveau, pas le sol

`level` additionne le sol et la profondeur, et c'est l'écart de `level` qui pousse. C'est ce qui fait qu'un lac reste plat sur un fond bosselé. Si l'on regardait le sol, ou la profondeur seule, le lac se mettrait à bouger tout seul. `test_un_lac_au_repos_reste_au_repos` pose un fond en sinus et vérifie le niveau à 0,0001 près.

### 3. On ne donne pas ce qu'on n'a pas

Sur une pente, une case presque sèche voit de grands écarts de niveau : ses débits lui retireraient plus d'eau qu'elle n'en a, et sa profondeur deviendrait négative. Si ce qu'elle veut donner dépasse ce qu'elle a, tous ses débits sont réduits d'autant. Quatre lignes suffisent (`leaving` et `share`), et elles évitent toute une famille de bugs.

### 4. L'eau ne se perd jamais

Ce qu'une case donne, sa voisine le reçoit : c'est le même nombre, lu des deux côtés. La somme des profondeurs ne peut donc pas changer. Les bords sont des murs : aucun débit n'y entre. `test_l_eau_ne_se_perd_jamais` n'est pas un réglage : c'est une propriété du schéma.

### 5. Deux passes, et un débit par canal

Il faut d'abord les débits, puis les profondeurs. La première passe, `flood_flow.glsl`, lit la profondeur et le sol. La seconde, `flood_depth.glsl`, lit les débits qu'on vient d'écrire : d'où l'échange de `_flow` entre les deux passes. Le processeur peut écrire sur place, parce qu'une case n'y lit que ses propres débits. La carte, elle, écrit toutes les cases en parallèle : elle a besoin de ses doubles.

Les quatre débits tiennent dans une image à quatre canaux. Elle doit partir de zéro : `new_color_texture` la vide maintenant sur la carte.

### 6. La même limite

Une onde dans ces tuyaux va à la racine de `pull`, en cases par seconde. C'est la limite de Courant de l'étape précédente : `WaveSolver.substeps` sert ici aussi.

### 7. Le relief et l'image

`hills` calcule un relief sans hasard : une pente, avec des vagues de terre. L'image du sol vient du processeur, une seule fois : le sol ne change pas. Seule la profondeur vit sur la carte.

## Ce qu'il faut retenir

Vagues : la surface oscille, l'eau reste. Eau peu profonde : l'eau se déplace, et sa quantité ne change jamais. Quand une propriété comme celle-là tient par construction, elle fait un excellent test.
