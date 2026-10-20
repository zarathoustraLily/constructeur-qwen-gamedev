# Kart · étape {STEP} · {TITLE}

**Piste : {TRACK}.** L'aire d'essai laisse la place à l'île : un terrain, un circuit, une ligne d'arrivée, des
rampes. Deux shaders l'habillent : celui du terrain, qui projette une texture sans coutures sur les pentes et
les falaises (projection triplanaire), et le shader stylisé de la piste, que le kart prend aussi.

Ce qu'on obtient : le kart part sur l'herbe, près du circuit. La mer n'est pas encore là : en attendant
l'étape 007, une mer provisoire, plate et solide, porte le kart au niveau 0.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier.
2. F5 : conduire sur l'île, prendre une rampe, rouler jusqu'à la mer.
3. Ouvrir `2_sequence/levels/island/island.tscn` : la scène du niveau.

## Les fichiers du projet

{FILES_TABLE}

## Ce qu'on a fait, dans l'ordre

### 1. Un niveau, une scène

L'île est une scène de `2_sequence/levels/island/` : un niveau appartient au déroulé du jeu. Elle contient
son soleil (`Sun`, avec ombres) et son environnement (`Environment2`, réglé par `environment_settings.tres`) :
la scène principale n'a plus les siens. Elle place aussi le kart au départ, à l'endroit où le jeu d'origine
le posait.

### 2. Des corps solides, sur des couches

Le terrain, le circuit et la ligne d'arrivée sont des `StaticBody3D`. Chacun a sa forme de collision : une
`ConcavePolygonShape3D`, c'est-à-dire la liste des triangles de son modèle. Ces listes, générées depuis les
modèles, sont rangées dans des ressources à part (`6_assets/models/…/collision/*.tres`) : la scène reste
lisible.

Le terrain est sur la couche 4 (Terrain), le circuit sur la couche 5 (Circuit), et le masque du kart (63)
contient les deux. Les rayons des roues (`collision_mask = 120`) cherchent le sol sur ces couches, et sur
les plaques de boost et les objets à venir.

### 3. La projection triplanaire

Une pente raide ou une falaise étire une texture plaquée par ses UV. Le shader du terrain
(`6_assets/shaders/environment/island.gdshader`) échantillonne la texture de bruit trois fois, une fois par
axe (sur les plans YZ, XZ et XY, à partir de la position dans le monde), puis mélange les trois selon la
normale : `sampleTriplanar()`, dans `triplanar_sampling.gdshaderinc`. Le sol plat prend surtout la projection
d'en haut, la falaise surtout celle de côté, et il n'y a plus d'étirement.

`render_mode world_vertex_coords` donne `VERTEX` directement dans le monde : le shader garde la position dans
une `varying` pour le fragment.

### 4. Choisir la couleur selon la pente et une carte

Le fragment part de la couleur de la roche. Si la normale est presque verticale (le produit scalaire avec le
haut dépasse 0,85), c'est un sol. La carte `terrain_material_map` (une texture lue par les UV du modèle) dit
alors lequel : chemin de terre (canal rouge), sable (canal vert) ou herbe (le reste). Le bruit triplanaire
fait varier la saturation et la clarté (`noiseColorTransformer`, dans `utils.gdshaderinc`) et la normale
(`noiseNormalTransformer`) : le sol n'est pas uni.

### 5. Le shader stylisé

La piste, ses bordures et le kart portent `stylized_shader.gdshader` : une couleur ou une texture, le même bruit
triplanaire, et des réglages de matière (`specular`, `roughness`, `metalic`). Le matériau du kart, standard
aux étapes 002 et 003, passe ici à ce shader. Le fichier contient aussi la pluie, qui n'arrivera qu'à
l'étape 011.

Les `.gdshaderinc` sont des morceaux de shader partagés, inclus par `#include`. `utils.gdshaderinc` se protège
d'une double inclusion par `#ifndef SHADER_UTILS` : deux shaders qui l'incluent chacun ne le définissent
qu'une fois.

### 6. La mer provisoire

`Sea` est un `StaticBody3D` avec une `WorldBoundaryShape3D` : un plan infini, au niveau 0. Il tient la place de
l'eau, et le kart y roule comme sur un sol. À l'étape 007, il sera remplacé par une vraie surface d'eau, sur
laquelle le kart flottera.

## Les tests

- `2_sequence/levels/island/test_island.gd` : terrain, circuit et arrivée solides ; couches Terrain et
  Circuit ; un kart posé au départ se pose sur le terrain ; soleil avec ombres, environnement ; rampes avec
  collision ; la mer provisoire porte le kart au niveau 0.
- `2_sequence/test_main.gd` : le kart se pose sur l'île au départ ; la caméra le suit.
- La vérification de l'étape rend une image en Compatibilité : c'est là que les shaders se compilent.

## Ce qu'il faut retenir

- Un niveau est une scène de `2_sequence`, avec sa lumière et son environnement.
- Des couches de collision nommées (`[layer_names]`) et des masques qui disent qui heurte quoi.
- La projection triplanaire pour texturer un terrain sans UV propres sur les pentes.
- Des morceaux de shader partagés par `#include`, protégés par `#ifndef`.

## À essayer

- Dans `island_material.tres`, changer `grass_color` : toute l'herbe change.
- Dans `island.gdshader`, passer le seuil 0,85 à 0,95 : seules les surfaces très plates restent de l'herbe, le
  reste devient de la roche.
- Mettre `detail_noise_normal_strength` à 0 : le sol devient lisse.

## Source

- Le niveau et ses shaders viennent du kart d'origine (GDWaterKart, JorisAR, licence MIT) : `island.tscn`,
  `island.gdshader`, `stylized_shader.gdshader`, `triplanar_sampling.gdshaderinc`, `utils.gdshaderinc`.
- Référence des classes `ConcavePolygonShape3D`, `WorldBoundaryShape3D`, `StaticBody3D` (API de Godot 4.7.2).
- Documentation de Godot 4.7, *Spatial shaders* (`tutorials/shaders/shader_reference/spatial_shader.rst`) :
  `render_mode world_vertex_coords`, `VERTEX`, `NORMAL`, `NORMAL_MAP`, `INV_VIEW_MATRIX`.

## Étape suivante

Étape 005 : le décor stylisé. Des rochers, des palmiers et des nuages, et le vent qui fait bouger les palmes.
