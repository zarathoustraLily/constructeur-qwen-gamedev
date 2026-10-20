# Kart · étape {STEP} · {TITLE}

**Piste : {TRACK}.** L'île se couvre d'herbe : 109 671 brins, rangés en 342 blocs. Les brins bougent au vent
et s'écartent sous le kart.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 : rouler dans l'herbe. Elle se couche autour du kart et se relève derrière lui.
3. Dans l'éditeur, ouvrir `2_sequence/levels/island/island_details.tscn` et sélectionner le nœud `Details` :
   l'inspecteur montre les règles du semis et les boutons « Generate Details » et « Clear Details ».

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un brin, mille fois : le MultiMesh

Un nœud par brin, ce serait cent mille nœuds. Un `MultiMesh` dessine le même maillage à de nombreuses places
en un seul appel de dessin : il ne garde qu'une transformation par exemplaire. Contrepartie : le moteur
n'écarte jamais un seul brin hors de la vue, le bloc est affiché en entier ou pas du tout. Le semis découpe
donc l'île en blocs : une grille de 32 × 32 sur 680 m, dont 342 blocs reçoivent de l'herbe. Chaque bloc est un
`MultiMeshInstance3D` (`DetailBlock000` à `DetailBlock341`), caché au-delà de 96 m (`visibility_range_end`).

### 2. Semer dans l'éditeur : un outil `@tool`

`1_core/tools/detail_populator.gd` tourne dans l'éditeur (`@tool`). `@export_tool_button` met deux boutons dans
l'inspecteur : `populate()` sème, `clear()` efface. Le semis est enregistré dans `island_details.tscn` : le jeu
ne sème rien au lancement, il charge les blocs.

Pour chaque bloc, `chunk_transforms()` lance des rayons verticaux sur une grille d'un mètre
(`PhysicsDirectSpaceState3D.intersect_ray`). Chaque point est décalé au hasard. Un point est gardé s'il remplit
quatre conditions :

- le rayon touche le corps du terrain (`collider`) ;
- le point est à 2 m de haut ou plus (`rules_vertical_range`) : pas d'herbe sur la plage ;
- la pente est faible : la normale, lue dans le maillage par `MeshDataTool` et interpolée sur le triangle par
  `Geometry3D.get_triangle_barycentric_coords`, reste proche du haut ;
- le canal vert du masque du terrain est presque nul à cet endroit : pas d'herbe sur la piste.

Le hasard passe par un `RandomNumberGenerator` de graine `random_seed` : une même graine donne le même semis.
Le kart d'origine tirait au hasard global ; la règle SIM-09 l'interdit dans la logique.

La lecture du masque (`ImageSampling.bilinear`, `1_core/tools/image_sampling.gd`) mélange quatre pixels
voisins. Celle du kart d'origine lisait un pixel hors de l'image sur le bord droit et le bord bas ; elle
s'arrête maintenant au dernier pixel. L'océan de l'étape 008 lira le masque de l'île avec la même fonction.

### 3. Le shader de l'herbe

Dans `6_assets/shaders/environment/grass.gdshader`, la fonction `vertex()` travaille dans le monde
(`world_vertex_coords`) :

- **le vent** : `get_wind_displacement()` (étape 005), pondéré par la couleur de sommet du brin, rouge
  (`COLOR.r`) : nulle au pied, presque 1 à la pointe. Le pied ne bouge pas ;
- **la hauteur** : le masque de l'île (`island_texture`) raccourcit l'herbe au bord des chemins ;
- **le kart** : à moins de `push_radius` (2 m) du kart, le brin est poussé vers l'extérieur et se couche.

Au loin, le fragment écarte des pixels selon une trame régulière (`dither.gdshaderinc`) entre 72 et 96 m :
l'herbe s'efface peu à peu au lieu de disparaître d'un coup.

### 4. La position du kart, pour les shaders : GameState

Le shader lit la position du kart dans un paramètre global, `player_position` (`project.godot`, section
`[shader_globals]`). Un singleton (autoload), `0_autoload/game_state.gd`, la porte : régler
`GameState.player_position` met à jour la variable et le paramètre global. La scène principale le fait à
chaque image physique. Le kart ne connaît ni les shaders ni GameState.

Le vent passe aussi dans GameState (`wind_direction`, `wind_strength`), avec les valeurs de départ de
`project.godot`. La pluie s'y ajoutera à l'étape 011.

## Les tests

- `1_core/tools/test_detail_populator.gd` : sur un terrain plat de 20 m, le semis remplit presque chaque point
  de la grille et range chaque bloc, nommé, à son coin ; même graine, même semis ; un masque vert ou une plage
  de hauteur hors du terrain n'en laissent aucun. Sans fenêtre, le moteur ne garde pas les transformations d'un
  MultiMesh : le test compare celles que calcule `chunk_transforms()`.
- `1_core/tools/test_image_sampling.gd` : au coin d'un pixel, sa couleur ; entre deux pixels, le mélange ;
  hors de l'image, noir ; au bord, aucune lecture hors de l'image.
- `0_autoload/test_game_state.gd` : chaque variable partagée a son paramètre global, et une valeur écrite se
  relit.
- `2_sequence/test_main.gd` : la position du kart arrive dans GameState.
- `2_sequence/levels/island/test_island.gd` : l'herbe de l'île est en blocs `DetailBlockNNN`.
- Le rendu de l'étape le vérifie à l'œil : sans `GameState.player_position`, l'herbe traverse le kart ; avec,
  elle s'écarte.

## Ce qu'il faut retenir

- Beaucoup d'objets identiques : un MultiMesh, découpé en blocs pour que le moteur écarte ceux hors de vue.
- Un outil `@tool` prépare les données dans l'éditeur ; le jeu les charge.
- Le hasard passe par une graine : un semis se refait à l'identique.
- Ce que les shaders partagent passe par un seul endroit (GameState), et non par des appels à RenderingServer
  dispersés dans le jeu.

## À essayer

- Dans `2_sequence/main.gd`, mettre la ligne `GameState.player_position = ...` en commentaire : l'herbe passe
  à travers le kart, et le test `test_la_position_du_kart_est_recopiee_pour_les_shaders` échoue.
- Dans `6_assets/models/grass/grass_material.tres`, passer `push_radius` à 4 : un grand cercle se couche
  autour du kart.
- Dans l'éditeur, changer `random_seed` du nœud `Details`, puis « Generate Details » : un autre semis.

## Source

- L'herbe, son shader et le semeur viennent du kart d'origine (GDWaterKart, JorisAR, licence MIT).
- Documentation de Godot 4.7 :
  - *Optimization using MultiMeshes* (`tutorials/performance/using_multimesh.rst`) : un seul appel de dessin,
    pas de tri des exemplaires hors de la vue, plusieurs MultiMesh pour plusieurs zones ;
  - *Running code in the editor* (`tutorials/plugins/running_code_in_the_editor.rst`) : `@tool` ;
  - *GDScript exported properties* (`tutorials/scripting/gdscript/gdscript_exports.rst`) :
    `@export_tool_button` ;
  - *Singletons (Autoload)* (`tutorials/scripting/singletons_autoload.rst`).
- Référence des classes (API de Godot 4.7.2) : `MultiMesh`, `MultiMeshInstance3D`, `PhysicsDirectSpaceState3D`,
  `MeshDataTool`, `Geometry3D`, `RandomNumberGenerator`, `GeometryInstance3D.visibility_range_end`.

## Étape suivante

Étape 007 : flotter. Une surface d'eau simple remplace la mer provisoire. Les bouées, les cônes et le kart
flottent dessus.
