# Paris · étape 009 · Comble en zinc, lucarnes, cheminées

**Pistes : Building et Shader.** L'immeuble reçoit son toit : un comble brisé, raide côté rue
puis presque plat, des lucarnes de quatre formes, deux souches de cheminée. Le zinc a son
shader. Et le shader de fenêtre apprend à découper des baies qui ne sont pas rectangulaires.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. E pour monter : le toit se regarde d'en
haut. Pour régler l'immeuble, ouvrir `{NAME}.tscn` : un groupe « Comble », et `zinc_brightness`
dans « Aspect ».

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Deux fichiers nouveaux : `…_toit.gd` et
`…_zinc.gdshader`.

## Ce qu'on a fait, dans l'ordre

### 1. Un script pour le toit

Le toit est un objet à part, qu'on pose sur une base rectangulaire. Il a son fichier,
`…_toit.gd`, et ne connaît de l'immeuble que ce qu'on lui donne :

```gdscript
RoofBuilder.build(_mesh, _materials, get_facade_width(), depth, base_y + CORNICE_HEIGHT,
		bay_centers, bay_width, brisis_angle, brisis_length, dormer_styles, chimneys)
```

Il reçoit l'outil de maillage et les matériaux de l'immeuble, et y ajoute ses pièces : tout
finit dans les mêmes maillages. Ses fonctions sont `static` : c'est une boîte à fonctions, pas
un objet.

C'est la règle qu'on suivra désormais : **quand un morceau d'immeuble peut se décrire par une
liste d'arguments, il a son script.**

### 2. Les pans : `_slab()`

Un pan de toiture est une boîte fine, inclinée. `_slab()` part d'un point bas, d'un angle et
d'une longueur, pose la boîte, et **renvoie le point haut**. Les pans s'enchaînent :

```gdscript
var front_break: Vector3 = _slab(mesh, zinc, width, front_eave, brisis_angle, brisis_length, 1.0)
var ridge: Vector3 = _slab(mesh, zinc, width, front_break, TERRASSON_ANGLE, run / cos(slope), 1.0)
```

Le brisis part de l'égout et monte raide ; le terrasson part de là où le brisis s'arrête et
monte doucement jusqu'au faîte. Même chose côté cour, avec `side = -1`. C'est le principe de
`_build_level()` à l'étape 006 : une fonction qui empile renvoie le point d'où partira la
suivante.

`box()` reçoit ici un argument de plus, une rotation : `Basis(Vector3.RIGHT, side * angle)`.

### 3. Les pignons : `polygon()`

Aux deux bouts, il faut fermer le comble. La forme a cinq sommets : les points que `_slab()`
vient de renvoyer. `polygon()` en fait une face, dans un repère tourné d'un quart de tour.

### 4. Les lucarnes : `_dormer()`

Une lucarne est un petit volume de zinc qui sort du brisis, avec une fenêtre. Quatre formes :

| Forme | Volume | Baie |
|---|---|---|
| Rectangulaire | une boîte, un toit plat débordant | rectangle |
| Cintrée | un profil en arc, extrudé vers la rue | arc surbaissé |
| À fronton | une boîte, un triangle extrudé | rectangle |
| Œil-de-bœuf | un profil en plein cintre | ovale |

Le profil en arc vient de `Profiles.arched_outline()`, extrudé avec le repère `facing_street`.
C'est l'extrusion de l'étape 008, dans une autre direction.

Plus le brisis est couché, plus la lucarne doit s'enfoncer pour le rejoindre en haut :
`dormer_depth` est calculé d'après la pente.

### 5. Des baies qui ne sont pas rectangulaires

La fenêtre d'une lucarne cintrée est un rectangle, comme toutes les fenêtres. C'est le shader
qui la découpe. Le script lui dit comment par une donnée attachée à l'instance :

```gdscript
custom = Color(SHAPE_ARCH, (rise - 0.1) / (0.5 * window_size.x), 0.0, 0.0)
mesh.panel(window_size, Transform3D(...), materials.dormer_window, custom)
```

`panel()` avait ce quatrième argument depuis le début. Dans le shader, il arrive par
`INSTANCE_CUSTOM` :

```glsl
v_custom = INSTANCE_CUSTOM;                 // dans vertex()
int shape = int(v_custom.x + 0.5);          // dans fragment() : 0 rectangle, 1 arc, 2 ovale
...
if (edge < 0.0) {
	discard;                                // hors de la forme : le pixel est jeté
}
```

Un seul matériau, un seul `MultiMesh`, et chaque instance a sa forme. Sans cela, il faudrait
un matériau par forme.

### 6. Les cheminées

Deux souches de pierre, aux deux bouts, coiffées de mitrons de terre cuite : des troncs de
cône, par `mesh.cone()`.

### 7. Le shader du zinc

À lire après la pierre : c'est **le même shader avec d'autres nombres**.

| | Pierre | Zinc |
|---|---|---|
| Grille | assises et blocs | bandes et feuilles |
| Joint | en creux | en relief : le tasseau |
| Tirage par case | teinte du bloc | teinte de la feuille, son gondolement |
| Bruit étiré | coulures vers le bas | coulures dans la pente |
| Brillance | mate | un peu métallique, moins sous la patine |

Une idée de plus : `METALLIC`. Le zinc neuf reflète comme un métal ; la patine et la saleté
le rendent mat. Le shader calcule donc `METALLIC` par pixel, comme `ROUGHNESS`.

`zinc_brightness` règle la luminosité d'ensemble : du vieux zinc sombre au zinc neuf.

## Ce qu'il faut retenir

1. Un morceau qui se décrit par des arguments a son script.
2. Des pièces qui s'enchaînent : chaque fonction renvoie le point d'où part la suivante.
3. Une donnée par instance (`INSTANCE_CUSTOM`) évite de multiplier les matériaux.
4. Un nouveau shader est souvent un ancien avec d'autres nombres.

## À essayer

- `brisis_angle` à 45 : le toit du règlement de 1859. À 80 : presque un mur.
- `dormer_style` : les quatre formes.
- `dormers` et `chimneys` décochés : le toit nu.
- `zinc_brightness` à 0,6, puis à 1,4.
- Dans le shader du zinc : `seam_spacing` à 0,8, `stagger` à 0.
{TWIN}
## Étape suivante

010 : le rez-de-chaussée. Une porte d'entrée, des boutiques, des enseignes.
