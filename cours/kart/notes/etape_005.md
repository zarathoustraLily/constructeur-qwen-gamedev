# Kart · étape {STEP} · {TITLE}

**Piste : {TRACK}.** L'île se peuple : quinze rochers, quarante-sept palmiers, une couche de nuages. Les
palmes bougent avec le vent, un vent que tous les shaders partagent.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 : rouler jusqu'aux palmiers. Le kart s'arrête contre leur tronc et contre les rochers.
3. Le vent : Projet > Paramètres du projet > Globales des shaders (`wind_direction`, `wind_strength`).

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un décor, des scènes réutilisées

Un rocher (`3_entities/decor/rock/rock.tscn`) ou un palmier (`3_entities/decor/palm/small_palm.tscn`) est une
petite scène : un maillage, son matériau, un corps solide. L'île en pose des dizaines d'instances (nœuds
`Rocks` et `Trees`), chacune avec sa position. Changer la scène d'un palmier change les quarante-sept.

Le rocher a une forme de collision exacte (`ConcavePolygonShape3D`) ; le palmier, une simple capsule autour
du tronc : les palmes ne bloquent pas le kart. Les deux sont sur la couche Terrain, comme le sol. Le rocher du
kart d'origine était sur la couche des karts : les rayons des roues (masque 120) et le bras de la caméra
(masque 30) ne le voyaient pas. Sur la couche Terrain, les roues se posent dessus et la caméra ne le traverse
plus.

### 2. Le vent : des paramètres globaux de shader

`wind_noise_texture`, `wind_direction` et `wind_strength` sont déclarés une fois pour tout le projet, dans
`project.godot`, section `[shader_globals]`. Un shader les lit par `global uniform`
(`6_assets/shaders/common/wind_displacement.gdshaderinc`). Aucun matériau ne les répète, et les changer change
le vent de tous les shaders à la fois : en jeu, par `RenderingServer.global_shader_parameter_set()`.

`get_wind_displacement(position, force)` lit le bruit du vent à la position du sommet, décalé avec le temps
(`TIME`) dans la direction du vent : les rafales passent sur l'île. Il rend un déplacement.

### 3. Les palmes bougent, le tronc non

Dans `palm.gdshader`, la fonction `vertex()` déplace chaque sommet par le vent, multiplié par le carré de sa
hauteur au-dessus du pied du palmier (`NODE_POSITION_WORLD`) : le pied ne bouge pas, la cime bouge beaucoup.
Le shader travaille dans le monde (`render_mode world_vertex_coords`).

Le modèle porte une couleur de sommet : rouge pour les palmes, sinon le tronc. Le fragment s'en sert pour
prendre la texture des feuilles ou celle de l'écorce. `cull_disabled` dessine les deux faces des palmes ; pour
le tronc, une face arrière est écartée (`discard`).

### 4. Les nuages

`cloud.tscn` est un seul plan, immense, au-dessus de l'île. Son shader (`clouds.gdshader`, `unshaded`)
fabrique les nuages avec du bruit qui glisse avec `TIME` (`speed`), et les rend plus ou moins transparents.
Pas de modèle, pas de texture : un ciel qui bouge pour le prix d'un rectangle.

## Les tests

- `3_entities/decor/test_decor.gd` : rochers et palmiers solides sur la couche Terrain ; un kart lancé à
  plein gaz sur un palmier, puis sur un rocher, ne le traverse pas ; les nuages ; le vent déclaré.
- La vérification de l'étape rend une image en Compatibilité : les shaders du décor s'y compilent.

## Ce qu'il faut retenir

- Une scène par objet de décor, des instances dans le niveau.
- Les paramètres globaux de shader pour ce que tout le monde partage (le vent).
- Déplacer des sommets dans `vertex()`, selon la hauteur, pour faire bouger une partie d'un modèle.
- Les couches de collision servent à tous : au kart, aux roues, à la caméra.

## À essayer

- Passer `wind_strength` à 6 : les palmes se couchent.
- Changer `wind_direction` : les palmes penchent de l'autre côté.
- Dans `small_palm.tscn`, désactiver la capsule : le kart traverse le palmier, et le test
  `test_le_kart_ne_traverse_pas_un_palmier` échoue.

## Source

- Le décor et ses shaders viennent du kart d'origine (GDWaterKart, JorisAR, licence MIT).
- Documentation de Godot 4.7, *Shading language* (`tutorials/shaders/shader_reference/shading_language.rst`) :
  les `global uniform`, déclarés dans les paramètres du projet.
- Référence de la classe `RenderingServer` (API de Godot 4.7.2) : `global_shader_parameter_set`.

## Étape suivante

Étape 006 : l'herbe. Des milliers de brins semés sur l'île en quelques blocs, et le vent dans l'herbe.
