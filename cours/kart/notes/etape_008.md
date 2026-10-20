# Kart · étape {STEP} · {TITLE}

**Piste : {TRACK}.** La mer calme devient un océan à houle, calculé sur la carte graphique par transformée
de Fourier rapide (FFT). Le kart et les bouées le suivent sans qu'une ligne de leur code change : l'océan
respecte le contrat WaterSurface de l'étape 007.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier. Le projet tourne en Forward+ : la houle a besoin des shaders de
   calcul (RenderingDevice).
2. F5 : rouler jusqu'à la mer. Le kart monte et descend avec la houle ; près de la plage, on voit le fond.
3. Les réglages de la houle : `5_data/water/ocean_settings.tres`, dans l'inspecteur.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. La houle par FFT, sur la carte graphique

`1_core/water/fft/ocean_fft_waves.gd` (classe `OceanFFTWaves`, une Resource) pilote cinq shaders de calcul
(`1_core/water/fft/shaders/*.glsl`), lancés par `RenderingDevice` sur le fil de rendu
(`RenderingServer.call_on_render_thread`) :

1. `initial_spectrum.glsl` : le spectre d'énergie des vagues, selon le vent (`wave_vector`). Il n'est recalculé
   que si le vent, la résolution ou la taille changent ;
2. `phase.glsl` : fait avancer dans le temps un hasard préparé au départ, entre deux textures qui
   alternent (ping-pong : on ne lit pas et n'écrit pas la même texture dans le même passage) ;
3. `spectrum.glsl` : combine les deux ;
4. `fft_horizontal.glsl` puis `fft_vertical.glsl` : la transformée inverse, lignes puis colonnes, donne la
   carte de déplacement : un décalage horizontal et une hauteur par pixel.

Trois cascades, d'échelles différentes (`cascade_scales` : 3,24, 1,62 et 0,5), superposent grande houle et
petites vagues : la répétition d'une seule texture se verrait. Les réglages du jeu : résolution 64 × 64,
carré de 256 m, `choppiness` 4, vent 300.

### 2. La hauteur de l'eau, côté processeur

La flottaison lit la hauteur sur le processeur. Une simulation sur trois (`heightmap_sync_frameskip` à 2), la
carte de déplacement est rapatriée sans attendre (`texture_get_data_async`) ; la simulation elle-même tourne
une image physique sur deux (`simulation_frameskip` à 1). `get_wave_height()` y lit le
pixel sous le point. Comme chaque pixel déplace aussi l'eau à l'horizontale, il retire ce déplacement et
relit plusieurs fois (`steps`), pour retrouver l'eau qui arrive vraiment à la verticale du point.

### 3. L'océan : le même contrat que la mer calme

`3_entities/ocean/ocean.gd` (classe `Ocean`) hérite de WaterSurface. Sa hauteur d'eau est celle de la houle,
multipliée par le masque de l'île (`island_water_mask.png`, canal rouge) : 0,18 au départ du kart, 1 au
large. Le capteur du kart et ceux des bouées appellent `get_wave_height()` comme à l'étape 007 : rien
d'autre ne change pour eux.

Deux corrections au passage, pour que la physique et l'image disent la même chose :

- **Hors du masque.** Le shader lit le masque sans répétition : au-delà de ses 960 m, il garde la couleur du
  bord, donc la houle. L'océan d'origine y lisait du noir, une eau plate. `ImageSampling.centered()` garde
  maintenant le bord, comme le shader.
- **La cadence.** La houle porte ce qui flotte : l'océan la fait avancer dans `_physics_process`, au rythme
  de la physique (règle SIM-01).

### 4. Le maillage : un arbre de niveaux de détail

`1_core/water/fft/quad_tree_3d_view.gd` (`QuadTree3DView`) découpe la surface en carrés imbriqués (CDLOD) :
cinq niveaux, un carré de 2 048 m à la racine, chaque carré un plan de 96 segments par côté, 341 carrés en
tout. Près de la caméra,
les carrés fins sont affichés, au loin les grossiers. Le shader passe en douceur d'un niveau à l'autre
(geomorph), grâce à trois paramètres d'instance par carré. Cet arbre ne fait qu'afficher : c'est une
présentation, d'où son nom en `_view`.

### 5. Sans carte graphique de calcul : la mer calme

En rendu de compatibilité, et sans fenêtre, `RenderingServer.get_rendering_device()` renvoie null : pas de
shaders de calcul, pas de houle. L'océan n'est jamais prêt et sa hauteur reste 0. L'arbre ne construit alors
aucun carré et montre sa surface de repli, la mer calme de l'étape 007 (`CalmSea`). Ce n'est pas qu'une
politesse : en compatibilité, la vérification de l'étape a relevé que les paramètres d'instance des 341 carrés
dépassent la réserve du moteur de rendu (« Maximum items supported by this hardware is: 4096 »).

### 6. Le shader de la surface

`6_assets/shaders/water/water_surface.gdshader` :

- **vertex()** déplace chaque sommet par les trois cascades, multipliées par le masque de l'île. Les
  coordonnées de lecture sont déformées par un bruit fixe (`domain_warp`) pour casser la répétition. La
  normale et le déterminant jacobien viennent des mêmes cartes ; le jacobien marque les crêtes qui se
  resserrent, où naît l'écume ;
- **fragment()** mélange le bleu profond et la couleur du ciel par Fresnel. Il ajoute la réfraction
  (`hint_screen_texture`, `hint_depth_texture`), les caustiques et le fond visible en eau peu profonde, décalé
  selon la pente de la surface. Viennent ensuite les réflexions en espace écran, la lumière qui traverse les
  vagues, et l'écume.

## Les tests

- `3_entities/ocean/test_ocean.gd` : sans fenêtre, la mer calme remplace l'océan et aucun carré n'est
  construit ; l'eau est plate ; le masque est faible sur l'île, vaut 1 au large et garde la valeur de son
  bord au-delà.
- `1_core/tools/test_image_sampling.gd` : la lecture centrée tombe au milieu de l'image, et garde la couleur
  du bord hors du carré.
- Les tests de l'étape 007 (capteurs, kart sur l'eau, bouées) passent sans changement : sans fenêtre, l'océan
  est plat, comme la mer calme.
- La vérification rend deux images : en Forward+, la houle ; en compatibilité, la mer calme, sans erreur.

## Ce qu'il faut retenir

- Un contrat bien choisi à l'étape 007 : on remplace l'eau entière sans toucher à ce qui flotte.
- Les shaders de calcul passent par RenderingDevice, qui n'existe pas partout : prévoir un repli.
- La physique lit sur le processeur ce que la carte graphique a calculé : rapatrier sans attendre, pas à
  chaque image.
- Beaucoup de maillage au loin coûte cher : des niveaux de détail, choisis selon la caméra.

## À essayer

- Dans `ocean_settings.tres`, passer `choppiness` de 4 à 8 : les crêtes deviennent pointues, et une large
  bande claire traverse la mer devant le kart.
- Dans les paramètres du projet, passer `rendering/renderer/rendering_method` à `gl_compatibility`, puis F5 :
  la mer calme remplace l'océan.

## Source

- L'océan vient du kart d'origine (GDWaterKart, JorisAR, licence MIT), lui-même tiré de godot4-oceanfft
  (Tessa Avery) et d'OceanFFT (Achal Pandey), licence MIT (`1_core/water/fft/LICENSE.txt`).
- Référence de la classe `RenderingServer` (API de Godot 4.7.2) : `get_rendering_device()` renvoie null avec
  le pilote OpenGL et sans fenêtre ; `call_on_render_thread`.
- Référence de la classe `RenderingDevice` : `texture_get_data_async`.
- Documentation de Godot 4.7, *Spatial shaders* (`tutorials/shaders/shader_reference/spatial_shader.rst`) :
  `instance uniform`, `hint_screen_texture`, `hint_depth_texture`.

## Étape suivante

Étape 009 : vagues d'impact et écume. Le kart soulève des vagues en tombant dans l'eau, et laisse un sillage
d'écume.
