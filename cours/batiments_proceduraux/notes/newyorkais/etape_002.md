# New York · étape 002 · Brique : appareil et joints

**Piste : Shader.** Le maillage ne change pas. On remplace la couleur unie du mur par un motif
que la carte graphique calcule pixel par pixel : des briques posées en assises, et leurs joints
de mortier. Aucune image n'est chargée.

## Ouvrir le projet

Comme à l'étape 001 : importer `project.godot` dans Godot 4.7.2, puis F5. Pour régler la tour,
ouvrir `{NAME}.tscn` et changer une variable du nœud racine. S'approcher d'un pilier avec la
caméra : une brique fait 20 cm de long et 7 cm de haut, joint compris.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Trois fichiers sont à lire, dans cet ordre : le
script de la tour, celui des matériaux, puis le shader, où est la leçon.

## Ce qu'on a fait, dans l'ordre

### 1. Ranger les fonctions de maillage dans `1_core`

À l'étape 001, le script contenait `_add_triangle`, `_add_quad`, `_add_box` et `_commit`. Ces
fonctions ne savent rien d'une tour : elles serviraient telles quelles à un lampadaire. Elles
n'ont donc rien à faire dans `6_assets/…/Building/`. Elles sont maintenant dans
`1_core/procedural/mesh_builder.gd`, le dossier des mécanismes génériques.

Dans le script de la tour, cela donne trois changements :

```gdscript
const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")

	_mesh = MeshBuilder.new()
	_mesh.commit(_root)
```

`MeshBuilder.new()` crée un outil neuf à chaque construction ; `_mesh.box(taille, centre,
matériau)` remplace `_add_box(surface, taille, centre)` ; `commit()` sort, à la fin, un maillage
par matériau.

L'outil tient lui-même un `SurfaceTool` par matériau. On lui dit « cette boîte est en brique »,
il la range avec les autres. C'est pour cela que les matériaux sont créés **avant** la
géométrie.

`box()` prend un quatrième argument, facultatif : l'orientation de la boîte. L'astuce de
l'étape 001, qui échangeait largeur et profondeur avec `abs()`, n'est plus utile : la boîte
tourne avec le repère de sa façade.

```gdscript
func _box_in(frame: Transform3D, size: Vector3, center: Vector3, material: Material) -> void:
	_mesh.box(size, frame * center, material, frame.basis)
```

`mesh_builder.gd` contient déjà tout ce dont les étapes suivantes auront besoin (profils
extrudés, rectangles instanciés). On ne s'en sert pas encore : à cette étape, seules `box()` et
`commit()` comptent.

### 2. Un script pour les matériaux

La géométrie et la matière sont deux métiers : le script de la tour dit **où** est la brique,
celui des matériaux dit à quoi elle **ressemble**. D'où un second fichier, `…_materiaux.gd`. La
tour s'en sert en trois temps :

```gdscript
	_materials = Materials.new()
	_materials.brick_color = brick_color
	_materials.build()
```

On règle, on fabrique, puis on s'en sert : `_materials.brick` pour les piliers et les bandeaux,
`_materials.core` pour le noyau. Dans `build()`, un `ShaderMaterial` est créé : un shader, plus
ses réglages.

```gdscript
	brick = _shader_material(BRICK_SHADER, {"brick_color": brick_color})
```

Chaque clé du dictionnaire est le nom d'un `uniform` du fichier `.gdshader`. C'est ainsi qu'une
variable de l'inspecteur arrive jusqu'à la carte graphique : tour, matériaux, shader.

### 3. Écrire le shader

Un shader « spatial » se lit en trois parties :

- les `uniform` sont ses réglages. Ils apparaissent dans l'inspecteur du matériau, et un script
  peut les fixer avec `set_shader_parameter()` ;
- `vertex()` tourne une fois par sommet ;
- `fragment()` tourne une fois par pixel. Il remplit `ALBEDO` (la couleur), `ROUGHNESS` (mat ou
  brillant), et le moteur calcule ensuite l'éclairage.

#### 3.1 Transmettre la position : `vertex()`

```glsl
varying vec3 v_pos;
varying vec3 v_nrm;

void vertex() {
	v_pos = VERTEX;
	v_nrm = NORMAL;
}
```

Un `varying` est une valeur calculée à chaque sommet, que `fragment()` reçoit fondue d'un sommet
à l'autre. Ici : la position et la normale dans le repère de la tour, en mètres. Tout le motif
en découle. Le maillage n'a besoin d'aucune coordonnée UV, et une brique mesure la même taille
sur tous les murs, du pilier de 80 cm au bandeau de 26 m.

#### 3.2 Des coordonnées de mur : `pc_face_frame()`

Un mur peut regarder dans n'importe quelle direction : la tour en a quatre. `pc_face_frame()`
fabrique, à partir de sa normale, deux axes posés sur lui : `t`, horizontal, et `b`, vers le
haut. La position projetée sur ces axes donne `u` (le long du mur) et `v` (la hauteur), en
mètres.

```glsl
	pc_face_frame(n, t, b);
	float u = dot(v_pos, t);
	float v = dot(v_pos, b);
```

#### 3.3 Les assises, avec `floor()`

`v / brick_size.y` est un nombre à virgule : sa partie entière est le numéro de l'assise, le
reste est la position dans l'assise.

```glsl
	float row = floor(v / brick_size.y);
	float vl = v - row * brick_size.y;
	float dy = min(vl, brick_size.y - vl);
```

`dy` est la distance au joint horizontal le plus proche, celui du dessous ou celui du dessus.

#### 3.4 L'appareil à boutisses

Un mur de brique new-yorkais n'est pas une simple pose en quinconce. Toutes les cinq, six ou
sept assises, un rang de **boutisses** : des briques posées en travers du mur, qu'on voit par
leur bout, deux fois plus court. Elles lient le parement au mur qui est derrière. C'est
l'appareil américain, le « common bond ».

```glsl
	bool header_row = header_every > 0 && mod(row, float(header_every)) < 0.5;
	float unit = header_row ? 0.5 * brick_size.x : brick_size.x;
	float shift = header_row ? 0.25 : (mod(row, 2.0) < 0.5 ? 0.0 : 0.5);
	float uu = u / unit + shift;
```

Trois lignes font tout :

- `header_row` : cette assise est-elle un rang de boutisses ? Une sur `header_every` ;
- `unit` : la longueur d'une brique dans cette assise. Une boutisse fait la moitié d'une
  panneresse (la brique vue sur sa longueur) ;
- `shift` : le décalage de l'assise. Les panneresses sont décalées d'une demi-brique une
  assise sur deux ; les boutisses, d'un quart de boutisse, pour que leurs joints ne s'alignent
  pas sur ceux des assises voisines.

Puis `floor()` encore donne le numéro de la brique dans son assise, et `dx`, la distance au
joint vertical le plus proche.

#### 3.5 Le joint, par une distance, filtré par `fwidth()`

On ne teste pas « suis-je dans un joint ? ». On mesure `dx` et `dy`, les distances aux joints
les plus proches, et tout le reste en découle.

```glsl
	float fu = fwidth(u);
	float half_joint = 0.5 * joint_width;
	float joint_mask = max(pc_band(dx, half_joint, fu), pc_band(dy, half_joint, fv));
```

`fwidth(u)` dit de combien `u` change d'un pixel au suivant : c'est la taille du pixel sur le
mur. `pc_band()` s'en sert pour donner au joint un bord large d'un pixel. Un joint de 9,5 mm est
plus fin qu'un pixel dès une dizaine de mètres : sans ce filtre, la tour entière fourmille dès
qu'on bouge. Et une tour se regarde de loin.

#### 3.6 La couleur

```glsl
	vec3 col = pc_color_in(brick_color);
	col = mix(col, pc_color_in(joint_color), joint_mask);
	ALBEDO = pc_color_out(col);
	ROUGHNESS = mix(0.85, 0.95, joint_mask);
```

`joint_mask` sert deux fois : il mélange les teintes, puis les rugosités. La brique est mate,
le mortier plus mat encore. `pc_color_in()` et `pc_color_out()` encadrent les mélanges de
couleur. Sans eux, le même shader ne donnerait pas la même image dans les trois moteurs de
rendu de Godot.

### 4. Les cotes de la brique

`brick_size` vaut 203,2 × 67,7 mm, joint compris : c'est la brique **modulaire** américaine,
8 pouces de long, et trois assises pour 8 pouces de haut. Le joint fait ⅜ de pouce, 9,5 mm.
Le rang de boutisses tombe toutes les six assises (`header_every`), la valeur du milieu de ce
que l'on rencontre (cinq, six ou sept). Ces nombres viennent des fiches techniques de la Brick
Industry Association (voir les sources).

### 5. Le fichier commun `procedural_commun.gdshaderinc`

Un fichier `.gdshaderinc` ne dessine rien : c'est une boîte à outils que chaque shader recopie
chez lui avec `#include`. Il vit dans `6_assets/Shader/Procedural/`, un cran au-dessus de
`DECORS/Building/`, parce qu'il sert à tous les décors. Les fonctions qui commencent par `pc_`
en viennent.

## Ce qu'il faut retenir

1. Partir de la position, en mètres : pas d'UV, et un motif à la bonne taille partout.
2. Fabriquer une grille avec `floor()` ; une règle de pose (les boutisses) est une ligne de plus.
3. Mesurer une distance au motif, plutôt que tester « dedans ou dehors ».
4. Filtrer avec `fwidth()` tout ce qui peut devenir plus fin qu'un pixel.
5. Une variable de l'inspecteur descend en trois étages : tour, matériaux, shader.

## À essayer

- `brick_color` dans l'inspecteur de la tour : un chamois clair (0,78 ; 0,66 ; 0,50).
- Dans le shader, `header_every` à 0 : un appareil en panneresses seules, sans boutisses.
- Dans le shader, `header_every` à 2 : un rang sur deux, la brique semble posée en damier.
- Remplacer la ligne `ALBEDO` par `ALBEDO = vec3(fract(v / brick_size.y));` : on voit la grille
  nue, un dégradé par assise.
- Remplacer `pc_band(dx, half_joint, fu)` par `step(dx, half_joint)` et reculer la caméra : la
  tour scintille.
{TWIN}
## Étape suivante

003 : le hachage et le bruit. Chaque brique tire sa teinte, la suie du charbon salit la façade
par grandes plages, la pluie coule, les joints se creusent.

## Sources

- Brick Industry Association, *Technical Notes 10, Dimensioning and Estimating Brick Masonry*,
  février 2009 : la brique modulaire, 8 pouces de long, trois assises pour 8 pouces, joint de
  ⅜ de pouce.
- Brick Industry Association, *Technical Notes 30, Bonds and Patterns in Brickwork*, mars 1999 :
  l'appareil américain (« common bond »), un rang de boutisses toutes les cinq, six ou sept
  assises.
