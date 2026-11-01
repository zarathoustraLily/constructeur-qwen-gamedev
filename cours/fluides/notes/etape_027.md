# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** SPH sur le processeur compte quelques centaines de particules. Sur la carte, des centaines de milliers : mais rien ne s'y écrit comme dans une boucle, surtout pas une liste chaînée.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Les shaders sont `1_core/gpu/shaders/sph_*.glsl`, leur appel `1_core/gpu/gpu_sph.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Des tampons, pas des images

Une particule n'est pas une case : positions, vitesses, densités vont dans des tampons, comme à l'étape 11. `ComputeDevice` gagne `new_vector_buffer` et `new_int_buffer`. En `std430`, un `vec2` est serré sur 8 octets : `PackedVector2Array.to_byte_array()`
tombe juste. Un `vec3` serait aligné sur 16 octets, et c'est un piège classique : ici, on reste en deux dimensions.

### 2. Une liste chaînée en parallèle

`rebuild_neighbours` sur le processeur fait deux gestes : lire la tête de la case, y écrire la particule. Lancés en même temps, deux invocations peuvent lire la même tête : l'une écrase l'autre, et une particule disparaît de la grille.
`atomicExchange` fait les deux gestes d'un seul coup. Il rend l'ancienne tête, qui devient la suivante. C'est tout : `links.data[i] = atomicExchange(heads.data[slot], int(i));`.

L'ordre des listes n'est plus celui du processeur : il dépend de qui arrive le premier. Ça ne change rien à une somme, mais le test ne peut pas comparer les listes : `test_chaque_particule_se_range_dans_la_liste_de_sa_case` parcourt
les listes, vérifie la case de chaque particule et compte qu'aucune ne manque.

### 3. Une boucle a une fin

Sur le processeur, `while j != -1` suffit. Sur la carte, une liste abîmée ferait tourner cette boucle sans fin, et un shader bloqué peut faire tomber le pilote, voire la machine. `density_from` et `force_from` bornent donc leur
boucle : `count < MAX_IN_CELL`. Une borne qu'on n'atteint jamais ne coûte rien.

### 4. Le même calcul, écrit pour la carte

`sph_density.glsl` et `sph_force.glsl` reprennent `SphKernels` et `_force_between` ligne à ligne. La somme se fait dans une fonction par case, `density_from` : le shader n'a pas de `neighbours_of` qui rendrait un tableau, il n'y a pas de tableau
à créer sur une carte. Une passe lit ce que la précédente a écrit (`densities` dans `sph_force.glsl`) : c'est pourquoi `update_forces` passe après `update_densities`, et Godot garde cet ordre.

### 5. Le processeur pour juge

Comme à l'étape 12, on donne les mêmes particules aux deux côtés. Densités, pressions et forces doivent coïncider, puis les positions après plusieurs pas. Là, l'écart permis grandit un peu : la carte calcule en 32 bits et GDScript
en 64, et ces petits écarts s'additionnent à chaque pas.

## Ce qu'il faut retenir

Tout ce qui lit puis écrit une même donnée partagée demande un geste atomique. Et sur une carte, toute boucle a une borne.
