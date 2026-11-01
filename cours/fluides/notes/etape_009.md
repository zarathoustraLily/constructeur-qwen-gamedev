# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le feu n'est pas une couleur : c'est un fluide qui brûle. Le carburant se change en chaleur, le gaz se dilate et pousse, l'air
chaud monte, la suie retombe.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Le feu est dans `1_core/fluid/combustion.gd`, ses réglages dans `1_core/data/fire_settings.gd`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Trois champs de plus

`FluidSolver` gagne `fuel`, `temperature`, `soot`. Sans `fire`, il ne fait que de la fumée. `_transport_fire` les transporte, comme la
matière, par la méthode `_carried`, qui échange chaque champ avec le double de travail.

### 2. Brûler

`Combustion.burn` brûle là où la température atteint `ignition` : `minf(fuel, burn_rate * delta)`, jamais plus qu'il n'y en a. Le
carburant brûlé donne de la chaleur (`heat`), de la suie (`soot_yield`), et une dilatation (`expansion`).

### 3. La dilatation

Le gaz brûlé prend de la place : `_project` retire `_expansion` de la divergence. La pression pousse alors vers l'extérieur, et la
flamme gonfle. C'est la seule façon d'avoir une explosion qui s'ouvre, et non une tache qui monte.

### 4. Monter et refroidir

`Combustion.lift` pousse `v` : la chaleur vers le haut (les y négatifs), la suie vers le bas. `Combustion.cool` retire la chaleur
par `exp(-rate * delta)` : le même refroidissement à toutes les cadences.

## Ce qu'il faut retenir

Un feu, c'est quatre lois simples sur un fluide. La dilatation dans la projection fait toute la différence entre une flamme et une tache.
