# Gardien du Comptoir · étape {STEP} · {TITLE}

**Piste : {TRACK}.** laurent : « accentue particulierement le travail et l'entrainnement sur l'optimisation des
performances il faut que le niveau puisse etre joue sur un petit pc ». Cette étape donne au niveau deux qualités
graphiques. La haute garde tout ; la basse vise une carte graphique intégrée. Le jeu choisit lui-même d'après la carte.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. Lancer avec `-- --qualite=basse` ou `-- --qualite=haute` pour forcer un niveau. Sans argument, le jeu lit le choix
   enregistré (`user://reglages.cfg`, section `graphismes`, clé `qualite`), sinon il prend la basse sur une carte
   intégrée, logicielle ou virtuelle.
3. Mesurer : `godot --path . --resolution 1280x720 --position -6000,-6000 -s res://7_tests/perf/mesurer_rendu.gd --
   180 180 rendu.png --qualite=basse`.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. L'inventaire de ce qui coûte

On a d'abord lu la scène, sans rien changer :
- **14 lumières du décor font des ombres**, presque toutes omnidirectionnelles en cube (six passes chacune), avec des
  portées de 12 à 51 m dans une salle d'environ 28 m. Il faut y ajouter la lune ;
- **l'environnement** : brouillard volumétrique, SDFGI, SSIL, SSAO et lueur ;
- **4,8 millions de triangles**, en version la plus détaillée, dont des centaines de petits objets ;
- un rendu en **1080p natif**.

### 2. Deux qualités, en données

`GraphicsQuality` (`1_core/data/`) dit ce que le rendu s'autorise. `quality_high.tres` garde tout.
`quality_low.tres` :
- coupe le SDFGI, le SSIL, le SSAO et le brouillard volumétrique ;
- rend la 3D à 0,67 de la résolution, puis l'agrandit par FSR 1 ;
- ne garde des ombres qu'aux deux lumières les plus proches du lieu du combat, en deux demi-sphères ;
- ramène les portées à 22 m, et les atlas d'ombres à 2048 ;
- multiplie la lumière ambiante par 2,5, pour rendre à la salle la lumière que lui renvoyait l'éclairage global.

`GraphicsQualityApplier` (`1_core/graphics/`) choisit le niveau et l'applique au démarrage. Il travaille sur une
**copie** de l'environnement : la ressource partagée reste intacte, ce qui compte pour les tests et pour un retour à la
qualité haute.

### 3. Ce que la mesure a montré

`7_tests/perf/mesurer_rendu.gd` ouvre le niveau dans une fenêtre hors de l'écran, en 1280 × 720. Il lit le temps de
rendu mesuré par la carte (`RenderingServer.viewport_get_measured_render_time_gpu`), en médiane, ainsi que les compteurs
du moteur. Mesures faites deux fois de suite, sur la 5090 :

| | Haute | Basse |
| --- | --- | --- |
| appels de dessin | 2 933 | 617 |
| primitives | 15,0 millions | 3,6 millions |
| temps de la carte graphique | 2,1 ms | 0,37 ms |
| temps du rendu côté processeur | 2,0 ms | 0,54 ms |
| mémoire vidéo | 893 Mo | 377 Mo |
| passes d'ombre par image (hors lune) | 64 | 3 |

Le temps de la carte dépend de ce qui tourne à côté d'elle. On compare donc deux réglages lancés l'un après l'autre,
plutôt que de lire un nombre seul.

### 4. Ce que l'image a appris

- **La brume de repli faisait une moquette blanche.** Des nappes non éclairées brillent dans une salle sombre. Les
  nappes (`mist_layers.gdshader`, trois plans au ras du plancher) prennent maintenant la lumière, comme le décor. Elles
  sont plus transparentes, avec des volutes plus douces, et s'effacent au contact du décor grâce à la profondeur de
  l'écran.
- **Sans éclairage global, la salle s'assombrit.** La lumière ambiante est relevée en qualité basse.
- **Le moteur Compatibilité** (OpenGL), souvent employé sur les petites machines, n'a pas les ombres en demi-sphères :
  480 erreurs en 60 images. Avec lui, on garde les cubes.

### 5. Les tests

- Le choix suit l'argument, puis le réglage enregistré, puis la carte graphique.
- La qualité basse allège le rendu : effets d'écran et brouillard coupés, brume de repli visible, échelle 3D et FSR,
  ombres aux seules lumières les plus proches, portées ramenées, moins d'un quart des passes d'ombre. La ressource
  partagée reste intacte.
- Revenir à la haute rend tout.

Avec les cas des étapes précédentes : 216 cas verts. Image en Compatibilité : seule reste la limite connue du
brouillard volumétrique.
