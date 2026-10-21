# Roguelike · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La salle de test devient un **modèle** de niveau, et trois niveaux en héritent : chacun
change ses tuiles, sa navigation, son décor (canapés, tonneaux, drapeaux), ses trous, la place de sa sortie et
son éclairage global précalculé.

Ce qu'on obtient : le jeu démarre au niveau 1, une grande salle ouverte. Les niveaux 2 et 3 s'ouvrent dans
l'éditeur (F6 sur la scène) ; à l'étape suivante, le chef d'orchestre les enchaînera.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 : le niveau 1. Pour les autres : ouvrir `2_sequence/levels/level_2/level_2.tscn`, puis F6.
3. Sélectionner `VoxelGI` dans un niveau, cocher puis décocher `visible` : la lumière renvoyée apparaît et
   disparaît.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un modèle et des scènes qui en héritent

`2_sequence/levels/level_template.tscn` est la salle de l'étape 10 : soleil, ciel, grilles sur leur région de
navigation, joueur, trou, limite du monde, vague, sortie, couche des chiffres. Son script,
`level_template.gd`, reprend la logique de `main.gd`, qui disparaît (avec l'affichage des commandes de
l'étape 1, qui n'était qu'un outil de mise au point).

`level_1.tscn`, `level_2.tscn`, `level_3.tscn` **héritent** du modèle (`instance=` sur la racine) : une scène
héritée ne garde que ce qui change. Les nœuds du modèle y apparaissent avec seulement `parent=` et les
propriétés remplacées (`data` des grilles, `navigation_mesh`, place du joueur et de la sortie) ; les nœuds
ajoutés (le décor `Litter`, les trous `Pit2`…) y ont leur `type=` ou leur `instance=`. Changer le modèle (son
ciel, sa vague) change les trois niveaux.

Chaque niveau a sa navigation, calculée dans l'éditeur pour ses tuiles. Le décor est posé **sous** la région de
navigation, et ses modèles reçoivent une collision à l'import (`"generate/physics": true` dans leurs `.import`) :
le calcul, qui lit les collisions (`geometry_parsed_geometry_type = 1`), en tient compte.

Les noms des tonneaux du jeu d'origine (`Barrel_A2`) deviennent `Barrel2` : les nœuds s'écrivent en PascalCase,
sans tiret bas (règle COD-01).

### 2. L'éclairage global : VoxelGI

Un `VoxelGI` découpe un volume en petits cubes (des voxels) et y précalcule la lumière que les surfaces se
renvoient : un mur bleu éclairé teinte le sol à côté de lui, les recoins s'assombrissent. Le calcul se fait
dans l'éditeur (bouton « Bake ») et s'enregistre dans une ressource `VoxelGIData` : chaque niveau a la sienne
(`level_1_voxel_gi_data.res`…), avec un volume ajusté à sa salle (`size`).

Rendu du niveau 2 avec et sans son VoxelGI : 465 602 pixels changent de façon visible (écart de plus de 8 sur
255), ombres plus profondes et murs teintés. Le VoxelGI est propre au rendu Forward+ : en Compatibilité, il ne
dessine rien, et les rendus de vérification en Compatibilité n'affichent aucune erreur.

### 3. La vibration du coup change de place

L'étape 1 faisait vibrer la manette quand on appuyait sur le bouton du coup, depuis la scène principale. Elle
passe dans la vue du joueur, au moment où l'épée part vraiment : le signal `slash` de l'emplacement de l'arme
(étape 6). Un coup demandé pendant un autre ne vibre que lorsqu'il s'enchaîne.

### 4. La scène de départ

`project.godot` démarre sur `level_1.tscn`. À l'étape suivante, une scène de démarrage remettra la séquence
des niveaux au chef d'orchestre, qui les chargera.

## Les tests

- `2_sequence/levels/test_levels.gd` : les trois niveaux héritent du modèle (joueur, vague, sortie, navigation,
  VoxelGI garni) ; chacun a sa navigation, sa lumière et sa sortie à lui ; dans chacun, le joueur se tient sur
  le sol ; chaque personnage a sa barre ; vaincu, le joueur revient au départ ; la vague vaincue ouvre la
  sortie, qui lance une vague plus nombreuse ;
- `3_entities/player/test_player_view.gd` : le départ d'un coup est écouté pour la vibration.

## Ce qu'il faut retenir

- Une scène héritée ne contient que ce qui change ; le modèle porte le reste.
- La navigation se calcule par niveau, décor compris.
- VoxelGI : une lumière renvoyée, précalculée dans une ressource, propre à Forward+.

## À essayer

- Dans `level_template.tscn`, passer `glow_enabled` à faux dans l'environnement : les trois niveaux perdent leur
  halo.
- Dans le niveau 2, déplacer un canapé, puis recalculer la navigation (bouton « Bake NavigationMesh », avec
  Débogage > Navigation visible) : le trou de la navigation suit le canapé.
- Dans le niveau 3, régler `VoxelGI.size` trop petit, puis « Bake » : seule une partie de la salle garde la
  lumière renvoyée.

## Source

- Le jeu d'origine (« GDTV-Roguelike », cours GameDev.tv) : modèle de niveau, trois niveaux (grilles, navigation,
  décor, trous, sortie, données VoxelGI) ; décor KayKit (GameDev.tv Free Sample Pack : canapé, tonneau,
  drapeau).
- Documentation de Godot 4.7 : *Using VoxelGI* (`tutorials/3d/global_illumination/using_voxel_gi.rst`) ;
  *Instancing* (`getting_started/step_by_step/instancing.rst`) ; *Using NavigationMeshes*
  (`tutorials/navigation/navigation_using_navigationmeshes.rst`).
- Références des classes `VoxelGI`, `VoxelGIData`, `NavigationRegion3D` (API de Godot 4.7.2).

## Étape suivante

Étape 012 : le chef d'orchestre. L'autoload `GameFlow` charge les niveaux dans un ordre tiré au hasard, avec la
boutique entre deux, des fondus au noir, et garde le joueur d'un niveau à l'autre.
