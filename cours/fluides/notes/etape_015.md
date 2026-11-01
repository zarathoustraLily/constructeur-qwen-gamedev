# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le feu rejoint le solveur de la carte. Il n'apporte que deux passes de plus ; il apporte surtout un piège de comparaison : un seuil.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Les passes sont dans `1_core/gpu/shaders/burn.glsl` et `lift.glsl`, leur appel dans `1_core/gpu/gpu_combustion.gd`, et le feu dans `gpu_solver.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. La combustion

`burn.glsl` écrit quatre images d'un coup : carburant, température, suie, dilatation. Six constantes, dans l'ordre exact du bloc du shader. `burned_in` garde
la règle : rien sous `ignition`, jamais plus qu'il n'en reste.

### 2. La poussée et la dilatation

`lift.glsl` pousse la vitesse verticale. La dilatation entre dans la projection : `GpuSolver._project` retire `_expansion` de la divergence par `add_scaled.glsl`,
après `divergence.glsl`. Le refroidissement n'a pas de passe à lui : c'est `GpuFieldOps.scale`.

### 3. Les trois champs de plus

`_carried` transporte un champ dans le double de travail, puis ce champ devient le nouveau double : le même `_next` sert à tous.

### 4. Une texture neuve n'est pas vide

Un `FluidField` neuf vaut zéro partout. Pas une texture de la carte : mesuré, une texture créée sans données juste après en avoir rendu une
autre, remplie de 7, contient 7 partout. La carte redonne la mémoire telle quelle. `ComputeDevice.new_texture` lui donne donc ses zéros dès la création.
`test_une_texture_neuve_est_vide_meme_apres_une_autre` provoque cette situation.

### 5. Une seule case, et tout diverge

Le premier essai s'écartait du processeur de 0,3 sur le carburant dès le premier pas, alors que chaque passe suivait le processeur. On découpe le pas :
l'écart naît à la combustion, et il vaut exactement `burn_rate × delta`, une case qui brûle d'un côté et pas de l'autre.

Quatre cases seulement, celles à 4 cases du centre d'un disque de rayon 5. Leur température est `1 - 4/5`. GDScript calcule en 64 bits et range en 32 : il obtient
0,2. La carte calcule en 32 bits : elle obtient 0,1999999881. Avec `ignition = 0.2`, l'une brûle, l'autre non. Le solveur n'a rien de faux : c'est le test qui tombait pile sur le seuil.

## Ce qu'il faut retenir

Comparer deux calculs en virgule flottante, c'est d'abord se méfier des seuils : une égalité exacte n'existe pas d'une machine à l'autre. Et une mémoire de carte n'est jamais vide.
