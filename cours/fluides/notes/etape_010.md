# Fluides · étape {STEP} · {TITLE}

**Piste : {TRACK}.** On branche le feu dans une scène : ses couleurs, ses réglages, la souris.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. La scène est dans `2_sequence/main.gd`, le feu dans `5_data/fluid/fire.tres` et `5_data/fluid/flame.tres`.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Les couleurs du feu

`FluidImage.colored` lit un `Gradient` à la hauteur de chaque valeur : noir, rouge, orange, presque blanc. Le dégradé est une donnée
de la scène : `ramp` dans `main.tscn`. Une image RGB8 est un tableau de trois octets par case.

### 2. Un feu qui se nourrit

`2_sequence/main.gd` verse du carburant et de la chaleur en bas de la grille à chaque image de physique. `_shown` montre la température.
`flame.tres` prend une grille de 48 × 64, moins de passes et le transport simple : en GDScript, chaque case coûte cher.

### 3. Ce que coûte le processeur

Mesuré sur la machine du cours, occupée par ailleurs : un pas de `flame.tres` (48 × 64 cases, 16 passes, transport simple) prend environ
400 ms en GDScript, soit 24 fois trop pour tenir 60 images par seconde. C'est la limite de cette partie du cours : le même calcul sur la
carte graphique, avec des shaders de calcul, en fera des millions de cases.

## Ce qu'il faut retenir

Tout passe par des données : réglages, feu, couleurs. La limite est maintenant le temps de calcul : c'est ce que réglera le GPU.
