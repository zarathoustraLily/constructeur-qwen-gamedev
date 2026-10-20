# Kart · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le kart laisse un sillage sur la mer : des ondulations sous les roues, deux traînées
d'écume et une vague derrière lui. Trois simulations de plus tournent sur la carte graphique, centrées sur le
kart.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (Forward+, comme à l'étape 008).
2. F5 : rouler dans la mer. Deux traînées blanches suivent les roues arrière ; la houle moutonne sur ses
   crêtes.
3. Les réglages du sillage : `5_data/kart/kart_wake.tres`.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Une propagation d'ondes, sur la carte graphique

`1_core/water/waves/water_waves.gd` (`WaterWaves`) fait vivre une texture de hauteurs centrée sur le joueur.
À chaque pas, le shader de calcul `water_waves_compute.glsl` lit les deux textures précédentes et écrit la
suivante : trois textures tournent. Cela suffit pour une équation d'onde, avec sa vitesse (`c2`) et son
amortissement (`damp`). Les impulsions arrivent par `add_ripple()`. Seules les quatre plus fortes de chaque pas
(hauteur × rayon) passent, la taille des « push constants » l'impose. Elles sont converties en pixels de la
texture.

L'océan en a deux :

- **WaterRipples** : les ondulations des roues, 2 048 pixels sur 64 m (32 pixels par mètre). Elles se
  dessinent seulement : leur texture ne revient pas sur le processeur (`use_cpu_readback` faux) ;
- **WaterWaves** : les vagues d'impact, 2 048 pixels sur 256 m (8 pixels par mètre). Leur texture revient sur
  le processeur un pas sur deux : `get_height()` s'ajoute à la houle dans `Ocean.get_wave_height()`, et ce qui
  flotte les sent. Elles avancent donc avec la physique (`_physics_process`, règle SIM-01).

Quand le joueur avance, la texture se recale (`texture_offset`), et le shader décale d'autant les deux
textures précédentes : les vagues restent en place dans le monde.

### 2. L'écume : une présentation

`1_core/water/waves/water_foam_view.gd` (`WaterFoamView`) accumule l'écume dans une texture de 512 m, à partir
des ondulations, des vagues d'impact, des crêtes de la houle et des points d'écume ajoutés par `add_foam()`.
L'écume ne porte rien : c'est une présentation, d'où son nom en `_view`. Elle tourne à chaque image
(`_process`). Elle attend que l'océan lui ait donné les textures de la houle avant son premier calcul.

### 3. Le contrat de l'eau s'agrandit

`WaterSurface` gagne `add_ripple()`, `add_wave()` et `add_foam()`. La surface de base les ignore ; l'océan les
envoie à sa simulation. Ce qui touche l'eau passe par ce contrat, sans connaître l'océan.

### 4. Le sillage du kart

`3_entities/kart/kart_wake.gd` (`KartWake`), un enfant du kart, travaille à chaque pas de physique. Si le kart
flotte et roule à plus de 1,5 m/s, il ajoute à la surface que lit son capteur :

- une ondulation sous chacune des quatre roues ;
- de l'écume sous les deux roues arrière ;
- une vague au milieu de l'essieu arrière.

La force suit la vitesse : 0,25 à 1,5 m/s, pleine à 15 m/s. Les positions des roues et tous les chiffres sont
dans `kart_wake.tres` (règle DAT-01).

Dans le kart d'origine, ce sillage vivait dans le script des gerbes d'eau, une présentation. Mais la vague
d'impact change la hauteur de l'eau que lit la physique : c'est de la logique. Les gerbes et les traînées
viendront à l'étape 010, dans les effets.

### 5. La scène principale relie l'océan au kart

À chaque pas, `main.gd` donne la position du kart à `Ocean.set_player_position()`, qui recentre les trois
simulations.

### 6. Le shader de l'eau lit les nouvelles textures

Dans `water_surface.gdshader`, `vertex()` ajoute aux déplacements de la houle la hauteur des vagues d'impact
et la moitié de celle des ondulations, multipliées par le masque de l'île. `fragment()` ajoute le masque
d'écume et les ondulations au mélange d'écume, et tire des ondulations une carte de normales.

### 7. Une mer reproductible

La houle tirait son hasard sans graine : deux parties identiques donnaient deux mers différentes. Elle part
maintenant de `random_seed`. Deux parties de 300 images, avec les mêmes commandes, donnent la même image, à
une unité de couleur près sur quelques pixels.

## Les tests

- `1_core/water/waves/test_water_waves.gd` :
  - au centre de la texture, le milieu ; un mètre vaut huit pixels ;
  - seules les quatre plus fortes impulsions passent, et l'attente se vide à chaque pas ;
  - hors de la texture, et sans fenêtre, la hauteur vaut 0.
- `3_entities/kart/test_kart_wake.gd` : sur une eau témoin, un kart qui roule laisse quatre ondulations,
  deux points d'écume et une vague derrière lui. Arrêté sur l'eau, ou sur le sol, il ne laisse rien.
- `3_entities/ocean/test_ocean.gd` : chaque ajout va à sa simulation, et les trois suivent le joueur.
- `2_sequence/test_main.gd` : l'océan suit le kart.

## Ce qu'il faut retenir

- Une équation d'onde se calcule avec trois textures qui tournent : avant-hier, hier, aujourd'hui.
- Ce qui change la physique est de la logique, même si ça se voit : la vague d'impact. Ce qui se dessine
  seulement est une présentation : l'écume.
- Un contrat qui grandit (WaterSurface) laisse le kart parler à l'eau sans connaître l'océan.
- Un hasard sans graine rend une image impossible à comparer.

## À essayer

- Dans `kart_wake.tres`, passer `foam_amount` à 0 : les traînées s'amincissent. Ce qui reste vient des
  ondulations, que le shader blanchit aussi.
- Dans `ocean_settings.tres`, changer `random_seed` : une autre mer.

## Source

- Les simulations d'ondes et d'écume, et le sillage, viennent du kart d'origine (GDWaterKart, JorisAR,
  licence MIT).
- Référence des classes `RenderingDevice` (`compute_list_*`, `texture_get_data_async`) et `Texture2DRD`
  (API de Godot 4.7.2).
- Documentation de Godot 4.7, *Using compute shaders* (`tutorials/shaders/compute_shaders.rst`).

## Étape suivante

Étape 010 : traînées, marques de pneus, gerbes d'eau et fantôme, avec le dérapage et le turbo.
