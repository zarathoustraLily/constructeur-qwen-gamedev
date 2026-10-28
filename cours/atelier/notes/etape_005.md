# Atelier · étape {STEP} · {TITLE}

**Piste : {TRACK}.** On regarde le monde : une caméra qui suit le joueur sans à-coups et ne traverse pas les murs,
et un soleil qui se lève, culmine et se couche.

Ce qu'on obtient : une caméra à la troisième personne qui tourne au stick droit autour de sa cible, se rapproche
quand un mur s'interpose, et un cycle jour-nuit qui fait varier l'angle, l'intensité et la couleur du soleil.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. Ouvrir `1_core/camera/follow_camera.tscn` : le pivot, le bras à ressort, la caméra au bout.
3. Les tests : double-cliquer `7_tests/lancer_tests.bat`, ou le panneau GdUnit4 de l'éditeur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un pivot, un bras, une caméra

`1_core/camera/follow_camera.tscn` : un `Node3D` (le pivot, qui suit la cible et tourne autour d'elle), un
`SpringArm3D` penché vers le bas, et la `Camera3D` au bout du bras. Le bras lance un rayon le long de sa longueur
(`spring_length`) sur les couches de son masque (ici, le monde) : si un mur coupe le rayon, la caméra s'arrête
devant, à `margin` près. `get_hit_length()` dit la longueur réellement tenue.

### 2. Suivre sans à-coups

Le pivot rejoint le point visé (la cible, relevée d'une hauteur) par un amortissement exponentiel :
`lerp(courant, but, 1 - exp(-vitesse × delta))`. Le même mouvement à 30 ou à 144 images par seconde, et aucune
secousse quand la cible s'arrête net. La caméra passe en dernier (`ProcessOrder.CAMERA`), après ce qui bouge.

### 3. Tourner autour de la cible

`orbit` change le lacet au rythme des réglages, le stick borné entre -1 et 1, et `wrapf` garde l'angle entre -PI et
PI. `ground_forward` donne la direction « avant » de la caméra sur le sol : c'est elle qui dira au joueur où
pousse le stick.

### 4. Le cycle jour-nuit

`1_core/lighting/day_cycle.gd` fait avancer l'heure de 0 à 1 (`fposmod` la fait boucler) et met le soleil à
l'heure : son angle (à l'horizon à l'aube, au zénith à midi), son énergie (nulle la nuit, maximale à midi :
`max(sin, 0)`), et sa couleur (`Color.lerp` de l'aube vers midi selon sa hauteur). Les fonctions de calcul sont
statiques : elles se testent sans scène.
