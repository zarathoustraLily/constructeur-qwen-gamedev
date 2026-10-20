# Kart · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La mer provisoire, un sol bleu, devient de l'eau. Le kart y roule en flottant, six
bouées y flottent, et dix-neuf cônes attendent sur le circuit que le kart les bouscule.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 : descendre vers la plage et continuer tout droit. Le kart tombe dans l'eau, rebondit, puis roule
   dessus ; Espace le fait sauter.
3. Foncer dans une bouée ou un cône : il est poussé, et le kart ne ralentit pas.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un contrat pour l'eau : WaterSurface

`1_core/water/water_surface.gd` dit ce qu'une surface d'eau doit savoir faire : donner la hauteur de l'eau à la
verticale d'un point (`get_wave_height`). Cette surface de base est plate, à hauteur 0. L'étape 008 la
remplacera par un océan à vagues, qui héritera du même contrat : rien de ce qui flotte n'aura à changer.

La mer de l'île (`Sea`, dans `island.tscn`) est un nœud de ce type, rangé dans le groupe global `ocean`
(`project.godot`, section `[global_group]`). Les capteurs y cherchent la surface de la scène : la mer et ce qui
flotte ne se connaissent pas.

### 2. Le shader de la mer calme

`6_assets/shaders/water/calm_water.gdshader` dessine un plan de 2 048 m qui reste plat : la flottaison lit une
eau plate, l'image doit la montrer plate aussi. Seule la normale ondule : trois vagues sinusoïdales, dans trois
directions, glissent avec `TIME`. La pente de leur somme donne la normale, et le reflet du soleil scintille.

- `NORMAL`, dans `fragment()`, est en espace de vue : la normale calculée dans le monde passe par `VIEW_MATRIX`.
- De face, on voit `deep_color` ; vers l'horizon, `far_color`. Le mélange suit `1 − dot(NORMAL, VIEW)` : c'est
  l'effet de Fresnel.
- Au-delà de 40 m, les ondulations s'effacent ; à 160 m, elles ont disparu. Plus fines qu'un pixel, elles
  scintilleraient.

### 3. Le capteur de flottaison

Un `WaterBuoyancySensor` (`1_core/water/buoyancy/`) est un point (`Marker3D`). À chaque pas de physique, il lit
la hauteur de l'eau à sa verticale. Il est « dans l'eau » quand la surface l'atteint, « sous l'eau » quand elle
le dépasse de sa hauteur (`height`). Sa normale est estimée par différences sur 10 cm.

Sans surface d'eau dans la scène, sa hauteur d'eau vaut −∞ : il n'est jamais dans l'eau. Le capteur d'origine
partait d'une eau à hauteur 0 : sur l'aire d'essai, sans mer, un kart posé sur le sol se serait cru dans l'eau.
Le test `test_sans_surface_d_eau_un_sol_a_hauteur_zero_reste_un_sol` le garde.

### 4. Ce qui flotte : BuoyantBody3D

Un `BuoyantBody3D` est un `RigidBody3D` qui pousse vers le haut à chaque capteur immergé, d'autant plus fort
que le capteur est profond (profondeur puissance `buoyancy_power`). La force s'applique au point du capteur
(`apply_force`, décalage depuis l'origine du corps) : un capteur plus enfoncé que les autres redresse le
corps. Immergé, le corps perd une part de sa vitesse à chaque pas de physique.

Une bouée (`3_entities/interactables/buoy/buoy.tscn`) a cinq capteurs : quatre en carré, à 6 m de l'axe et
4 m sous le centre, qui la tiennent droite, et un en haut, à 3,70 m. Sa poussée est multipliée par `delta`
alors qu'`apply_force` s'applique déjà pendant un pas : les multiplicateurs, 1 000 dans la scène et 4 000 sur
l'île, sont réglés avec ce facteur, donc pour 60 pas par seconde.

Un cône (`traffic_cone.tscn`) est un simple `RigidBody3D` : il ne flotte pas, il se renverse.

### 5. Le kart sur l'eau

Le kart reçoit un capteur, 40 cm sous son origine. Sur l'eau, `is_on_ground()` est vrai : le moteur, la
direction et le saut marchent comme au sol. `apply_water()` le ramène à 20 cm au-dessus de la surface
(`water_ride_height`) en deux temps :

1. pendant 2 s (`water_settle_time`), un ressort le rappelle. Il est raide quand le kart s'enfonce, doux
   quand il remonte : tombé de 2 m, le kart plonge jusqu'à 93 cm sous la surface, puis remonte ;
2. après 1 s (`water_stick_delay`), il est collé à sa hauteur, de plus en plus fort, et sa vitesse verticale
   s'éteint.

Ces chiffres sont des réglages, dans le groupe « Eau » de `kart_settings.tres`, en taux par seconde comme à
l'étape 002. Le kart d'origine écrivait `pow(0.8, 60 × dt)`, soit un taux de 60 × ln 1,25 ≈ 13,39 par seconde.

La présentation (`kart_view.gd`) penche le modèle selon la pente de l'eau sous le kart, lissée.

### 6. Les couches : pousser sans être arrêté

Bouées et cônes sont sur la couche 7, Interactables. Leur masque (219) contient la couche des karts : ils
heurtent le kart et sont poussés. Le masque du kart (63, couches 1 à 6) ne contient pas la couche 7 : le
kart ne les heurte pas, et rien ne le freine.

## Les tests

- `1_core/water/buoyancy/test_water_buoyancy_sensor.gd` : dans l'eau, sous l'eau, sur l'eau, profondeur ;
  sans surface, jamais dans l'eau ; avec une surface, la hauteur et la pente lues sous le capteur.
- `1_core/water/buoyancy/test_buoyant_body_3d.gd` : capteurs repérés, immersion, freinage, poussée qui suit
  les multiplicateurs et la profondeur, capteur décalé qui fait pencher.
- `3_entities/kart/test_kart_on_water.gd` : tombé dans l'eau, le kart rebondit sans couler, puis flotte à
  20 cm ; il y roule et en saute.
- `3_entities/interactables/test_interactables.gd` : le kart pousse un cône sans être arrêté.
- `2_sequence/levels/island/test_island.gd` : la mer est la surface de la scène ; au large, le kart flotte ;
  les bouées flottent, immobiles.
- Les tests utilisent une surface témoin (`7_tests/1_core/water/surface_temoin.gd`), dont on choisit la
  hauteur en chaque point : une pente, une marche.
- Le rendu de l'étape compile le shader de la mer, en Compatibilité.

## Ce qu'il faut retenir

- Un contrat (une classe de base) entre l'eau et ce qui flotte : on change d'eau sans toucher au reste.
- La physique et l'image doivent dire la même chose : une eau plate, des normales qui ondulent.
- Une valeur par défaut est une décision : −∞, « pas d'eau », vaut mieux que 0, « de l'eau partout ».
- Les couches et les masques décident qui heurte qui, et ce n'est pas forcément réciproque.

## À essayer

- Dans `calm_water.gdshader`, écrire `NORMAL = world_normal;` (sans `VIEW_MATRIX`) : le reflet du soleil
  disparaît, et toute la mer prend la couleur du large.
- Dans `kart_settings.tres`, passer `water_spring_down` à 5 : tombé de 2 m, le kart plonge à 3,32 m sous la
  surface avant de remonter.
- Ajouter la couche 7 au masque du kart (`kart.tscn`, 127) : il bute contre le premier cône et s'arrête.

## Source

- L'eau, la flottaison, les bouées et les cônes viennent du kart d'origine (GDWaterKart, JorisAR, licence
  MIT) ; la mer calme est propre à ce cours.
- Documentation de Godot 4.7 :
  - *Spatial shaders* (`tutorials/shaders/shader_reference/spatial_shader.rst`) : `NORMAL` en espace de vue
    dans `fragment()`, `VIEW`, `CAMERA_POSITION_WORLD` ;
  - *Physics introduction* (`tutorials/physics/physics_introduction.rst`) : `collision_layer` et
    `collision_mask` ;
  - *Groups* (`tutorials/scripting/groups.rst`) : les groupes globaux des paramètres du projet.
- Référence de la classe `RigidBody3D` (API de Godot 4.7.2) : `apply_force`, `_integrate_forces`.

## Étape suivante

Étape 008 : la mer FFT. Un océan à vagues, calculé sur la carte graphique, remplace la mer calme. Le kart et
les bouées le suivent sans rien changer.
