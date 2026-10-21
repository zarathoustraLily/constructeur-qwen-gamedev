# Roguelike · étape {STEP} · {TITLE}

**Piste : {TRACK}.** Le héros quitte l'estrade pour le niveau de test du jeu d'origine : un sol et des murs
posés en tuiles, un trou au milieu, et le vide tout autour. Sous le niveau, une limite du monde rattrape ce
qui tombe ; la caméra tremble à l'arrivée.

Ce qu'on obtient : la salle bleue du jeu d'origine, éclairée par un soleil rasant, sous un ciel en dégradé.
Le joueur y marche. S'il sort par un bord, il tombe, puis revient à son point de départ et l'image tremble.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5. Marcher jusqu'à un bord extérieur et continuer : chute, retour au départ, tremblement.
3. Dans l'éditeur, sélectionner `Floormap` : le panneau GridMap montre les tuiles disponibles ; on peut en
   poser d'autres au clic.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un niveau en tuiles : GridMap

Un `GridMap` est une grille 3D dont chaque case peut recevoir une tuile, prise dans une **bibliothèque de
maillages** (`MeshLibrary`). Deux grilles font le niveau, comme dans le jeu d'origine :

- `Floormap` : le sol, avec `6_assets/meshlibs/floormap.tres`, en cases de 4 × 0,5 × 4 m ;
- `Wallmap` : les murs, avec `6_assets/meshlibs/wall_map.tres`, en cases de 2 × 4 × 2 m, sans centrage en
  `x` ni en `z` (`cell_center_x = false`) pour que les murs tombent sur les bords des cases du sol.

Les tuiles de la bibliothèque portent leurs formes de collision : le joueur marche sur le sol et bute sur les
murs sans autre nœud. Les cases posées sont rangées dans `data`, en triplets d'entiers (position de la case,
puis numéro de la tuile et rotation) ; on ne les écrit pas à la main, on les peint dans l'éditeur.

Les tuiles autour du trou ont un rebord : en marchant, on le longe sans tomber. On tombe en sortant du
niveau par un bord extérieur.

### 2. La limite du monde

`1_core/zones/world_boundary.gd` (`WorldBoundary`) est une `Area3D` dont la forme est un
`WorldBoundaryShape3D` : un plan, ici 4 m sous le sol, et tout ce qui est en dessous est « dedans ». Quand un
corps y entre (`body_entered`), elle émet `body_fell(body)`.

La limite ne décide rien : elle signale. C'est la scène qui choisit quoi faire du corps tombé. Pour l'instant,
le joueur n'a pas de santé : `main.gd` le remet à son point de départ, vitesse nulle. À l'étape 6, la chute lui
coûtera toute sa santé, comme dans le jeu d'origine.

Le projet utilise Jolt (`physics/3d/physics_engine`). Avec Jolt, la référence de `WorldBoundaryShape3D`
précise que ce plan n'est pas infini : il a une taille finie, centrée sur son origine, réglée par
`physics/jolt_physics_3d/limits/world_boundary_shape_size` (2 000 m par défaut). Le niveau, d'une
vingtaine de mètres, tient largement dedans.

### 3. La caméra qui tremble

`1_core/camera/shake_camera_3d.gd` (`ShakeCamera3D`) étend `Camera3D`. Un bruit (`FastNoiseLite`) décale
l'image à l'écran (`h_offset`, `v_offset`), multiplié par un « trauma » de 0 à 1. `quick_shake(force)` met le
trauma à `force`, puis un `Tween` le ramène à zéro en `shake_duration` (0,3 s).

Le jeu d'origine lisait le bruit au fil de l'horloge (`Time.get_ticks_msec()`) : deux parties jouées à
l'identique ne tremblaient pas pareil, et une image rendue dépendait de l'heure. Ici, la caméra compte son
propre temps de jeu (`_time += delta × noise_speed`, avec `noise_speed` = 1000 pour garder le même rythme) :
mêmes entrées, même image. C'est ce qui permet de comparer deux rendus pixel par pixel.

Le `Tween` tourne au pas de la physique (`TWEEN_PROCESS_PHYSICS`), comme la caméra, et s'arrête en pause.

### 4. Le niveau du jeu d'origine

`main.tscn` reprend le niveau modèle du jeu d'origine : son soleil (ombres réparties sur 48 m), son ciel (un
`PanoramaSkyMaterial` dont l'image est un dégradé, `GradientTexture2D`), son halo (`glow_enabled`), ses deux
grilles, le trou (un plan noir sans éclairage, `shading_mode = 0`) et le point de départ du joueur (4, 1, 0).

## Les tests

- `1_core/zones/test_world_boundary.gd` : un corps sous la limite est signalé, un corps au-dessus ne l'est
  pas ;
- `1_core/camera/test_shake_camera_3d.gd` : immobile sans trauma ; `quick_shake()` fait trembler, puis le
  calme revient ; deux caméras au même bruit tremblent à l'identique ;
- `2_sequence/test_main.gd` : le joueur se tient sur le sol du niveau ; tombé sous la limite, il revient à son
  départ et la caméra tremble.

## Ce qu'il faut retenir

- `GridMap` et `MeshLibrary` : un niveau en tuiles, collisions comprises.
- Une zone signale, la scène décide.
- Un effet qui dépend du temps se règle sur le temps de jeu, pas sur l'horloge : il devient reproductible.

## À essayer

- Dans l'éditeur, peindre une case de sol dans le trou (`Floormap`, tuile 1) : le trou se referme.
- Passer `offset_scale` de la caméra à 10 : le tremblement devient violent.
- Remplacer `_time += delta * noise_speed` par la lecture de l'horloge, comme à l'origine, puis rendre deux
  fois la même image avec la capture : elles diffèrent.

## Source

- Le jeu d'origine (« GDTV-Roguelike », cours GameDev.tv) : niveau modèle (grilles, trou, soleil, ciel),
  bibliothèques de tuiles (paquet KayKit GameDev.tv Free Sample Pack), limite du monde, caméra qui tremble
  (bruit, trauma, 0,3 s, amplitude 3).
- Documentation de Godot 4.7, *Using GridMaps* (`tutorials/3d/using_gridmaps.rst`) : bibliothèque de
  maillages, collisions des tuiles.
- Référence de `WorldBoundaryShape3D` (4.7) : le plan, et sa taille finie avec Jolt.
- Références des classes `Area3D` (`body_entered`), `Camera3D` (`h_offset`, `v_offset`), `FastNoiseLite`,
  `Tween` (API de Godot 4.7.2).

## Étape suivante

Étape 005 : l'esquive. Un nouvel état du joueur, une recharge, une traînée dessinée par un shader et un son.
