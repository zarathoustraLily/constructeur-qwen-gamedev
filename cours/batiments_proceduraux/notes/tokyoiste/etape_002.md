# Tokyo · étape 002 · Carrelage : carreaux et joints

**Piste : Shader.** Le maillage ne change pas. On remplace la couleur unie du mur par un motif
que la carte graphique calcule pixel par pixel : des rangs de petits carreaux émaillés et
leurs joints de ciment. Aucune image n'est chargée.

## Ouvrir le projet

Comme à l'étape 001 : importer `project.godot` dans Godot 4.7.2, puis F5. Pour régler
l'immeuble, ouvrir `{NAME}.tscn` et changer une variable du nœud racine. S'approcher du mur
avec la caméra : les carreaux font 6 cm de haut.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Trois fichiers sont à lire, dans cet ordre :
le script de l'immeuble, celui des matériaux, puis le shader, où est la leçon.

## Ce qu'on a fait, dans l'ordre

### 1. Ranger les fonctions de maillage dans `1_core`

À l'étape 001, le script contenait `_add_triangle`, `_add_quad`, `_add_box` et `_commit`.
Ces fonctions ne savent rien d'un immeuble : elles serviraient telles quelles à un poteau
électrique. Elles n'ont donc rien à faire dans `6_assets/…/Building/`. Elles sont maintenant
dans `1_core/procedural/mesh_builder.gd`, le dossier des mécanismes génériques.

Dans le script de l'immeuble, cela donne trois changements :

```gdscript
const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")

	_mesh = MeshBuilder.new()
	_mesh.commit(_root)
```

`MeshBuilder.new()` crée un outil neuf à chaque construction ; `_mesh.box(taille, centre,
matériau)` remplace `_add_box(surface, taille, centre)` ; `commit()` sort, à la fin, un
maillage par matériau.

L'outil tient lui-même un `SurfaceTool` par matériau. On lui dit « cette boîte est en
carrelage », il la range avec les autres. C'est pour cela que les matériaux sont créés
**avant** la géométrie.

`mesh_builder.gd` contient déjà tout ce dont les étapes suivantes auront besoin (profils
extrudés, rectangles instanciés). On ne s'en sert pas encore : à cette étape, seules `box()`
et `commit()` comptent.

### 2. Un script pour les matériaux

La géométrie et la matière sont deux métiers : le script de l'immeuble dit **où** est le
carrelage, celui des matériaux dit à quoi il **ressemble**. D'où un second fichier,
`…_materiaux.gd`. L'immeuble s'en sert en trois temps :

```gdscript
	_materials = Materials.new()
	_materials.tile_color = tile_color
	_materials.build()
```

On règle, on fabrique, puis on s'en sert : `_materials.facade` pour le mur sur rue,
`_materials.side` pour le volume arrière.

Dans `build()`, un `ShaderMaterial` est créé : un shader, plus ses réglages.

```gdscript
	facade = _shader_material(TILE_SHADER, {
		"tile_color": tile_color,
	})
```

Chaque clé du dictionnaire est le nom d'un `uniform` du fichier `.gdshader`. C'est ainsi
qu'une variable de l'inspecteur arrive jusqu'à la carte graphique : immeuble, matériaux,
shader.

Le matériau s'appelle `facade`, et non `tile` : c'est le revêtement de la façade. À l'étape
011, la graine pourra y mettre autre chose que du carrelage, sans qu'une seule ligne de
l'immeuble change.

### 3. Écrire le shader

Un shader « spatial » se lit en trois parties :

- les `uniform` sont ses réglages. Ils apparaissent dans l'inspecteur du matériau, et un
  script peut les fixer avec `set_shader_parameter()` ;
- `vertex()` tourne une fois par sommet ;
- `fragment()` tourne une fois par pixel. Il remplit `ALBEDO` (la couleur), `ROUGHNESS` (mat
  ou brillant), et le moteur calcule ensuite l'éclairage.

#### 3.1 Transmettre la position : `vertex()`

```glsl
varying vec3 v_pos;
varying vec3 v_nrm;

void vertex() {
	v_pos = VERTEX;
	v_nrm = NORMAL;
}
```

Un `varying` est une valeur calculée à chaque sommet, que `fragment()` reçoit fondue d'un
sommet à l'autre. Ici : la position et la normale dans le repère de l'immeuble, en mètres.
Tout le motif en découle. Le maillage n'a donc besoin d'aucune coordonnée UV, et un carreau
mesure la même taille sur tous les murs.

#### 3.2 Des coordonnées de mur : `pc_face_frame()`

Un mur peut regarder dans n'importe quelle direction. `pc_face_frame()` fabrique, à partir
de sa normale, deux axes posés sur lui : `t`, horizontal, et `b`, vers le haut. La position
projetée sur ces axes donne `u` (le long du mur) et `v` (la hauteur), en mètres.

```glsl
	pc_face_frame(n, t, b);
	float u = dot(v_pos, t);
	float v = dot(v_pos, b);
```

#### 3.3 Une grille avec `floor()`

`v / tile_size.y` est un nombre à virgule : sa partie entière est le numéro du rang, le reste
est la position dans le rang.

```glsl
	float row = floor(v / tile_size.y);
	float vl = v - row * tile_size.y;
	float dy = min(vl, tile_size.y - vl);
```

`dy` est la distance au joint horizontal le plus proche, celui du dessous ou celui du dessus.
Même recette dans l'autre sens, avec une ligne de plus : un rang sur deux est décalé.

```glsl
	float shift = mod(row, 2.0) < 0.5 ? 0.0 : stagger;
	float uu = u / tile_size.x + shift;
```

`stagger` vaut 0,5 : c'est la pose à joints croisés, chaque joint vertical tombe au milieu du
carreau du dessous. À 0, les joints s'alignent en quadrillage : l'autre pose courante, qu'on
retrouvera à l'étape 011.

#### 3.4 Le joint, par une distance

On ne teste pas « suis-je dans un joint ? ». On mesure `dx` et `dy`, les distances aux joints
les plus proches, et tout le reste en découle. Cette habitude servira dans tous les shaders
du cours.

#### 3.5 Filtrer : `fwidth()`

```glsl
	float fu = fwidth(u);
	float half_joint = 0.5 * joint_width;
	float joint_mask = max(pc_band(dx, half_joint, fu), pc_band(dy, half_joint, fv));
```

`fwidth(u)` dit de combien `u` change d'un pixel au suivant : c'est la taille du pixel sur le
mur. `pc_band()` s'en sert pour donner au joint un bord large d'un pixel. De loin, un joint
plus fin qu'un pixel s'estompe au lieu de scintiller.

Avec des carreaux de 6 cm et des joints de 8 mm, ce filtrage n'est pas un raffinement : à
10 m, un joint fait déjà moins d'un pixel, et vers 40 m (en 1280 × 720) c'est un rang entier
de carreaux. Sans lui, la façade entière fourmille dès qu'on bouge.

#### 3.6 La couleur et le brillant

```glsl
	vec3 col = pc_color_in(tile_color);
	col = mix(col, pc_color_in(joint_color), joint_mask);
	ALBEDO = pc_color_out(col);
	ROUGHNESS = mix(0.4, 0.9, joint_mask);
```

`joint_mask` sert deux fois : il mélange les teintes, puis les brillants. Le carreau émaillé
est lisse (0,4), le ciment est mat (0,9). C'est ce qui distingue ce mur d'un mur de brique :
le ciel s'y reflète.

`pc_color_in()` et `pc_color_out()` encadrent les mélanges de couleur. Sans eux, le même
shader ne donnerait pas la même image dans les trois moteurs de rendu de Godot.

### 4. Le format des carreaux

`tile_size` vaut 235 × 68 mm, joint compris : un carreau de 227 × 60 mm et un joint de 8 mm.
C'est le format allongé le plus courant sur les façades japonaises. Cette cote est citée de
mémoire : à vérifier dans un catalogue de fabricant avant de s'y fier.

### 5. Le fichier commun `procedural_commun.gdshaderinc`

Un fichier `.gdshaderinc` ne dessine rien : c'est une boîte à outils que chaque shader
recopie chez lui avec `#include`. Il vit dans `6_assets/Shader/Procedural/`, un cran
au-dessus de `DECORS/Building/`, parce qu'il sert à tous les décors. Les fonctions qui
commencent par `pc_` en viennent.

## Ce qu'il faut retenir

1. Partir de la position, en mètres : pas d'UV, et un motif à la bonne taille partout.
2. Fabriquer une grille avec `floor()`.
3. Mesurer une distance au motif, plutôt que tester « dedans ou dehors ».
4. Filtrer avec `fwidth()` tout ce qui peut devenir plus fin qu'un pixel.
5. Une variable de l'inspecteur descend en trois étages : immeuble, matériaux, shader.

## À essayer

- `tile_color` dans l'inspecteur de l'immeuble : un brun (0,55 ; 0,38 ; 0,28).
- Dans le shader, `stagger` à 0 : les joints verticaux s'alignent.
- Dans le shader, `tile_size` à (0,05 ; 0,05) : une mosaïque carrée.
- Remplacer la ligne `ALBEDO` par `ALBEDO = vec3(fract(v / tile_size.y));` : on voit la
  grille nue, un dégradé par rang.
- Remplacer `pc_band(dx, half_joint, fu)` par `step(dx, half_joint)` et reculer la caméra :
  le mur scintille.
{TWIN}
## Étape suivante

003 : le hachage et le bruit. Chaque carreau tire sa teinte et son reflet, la pluie coule,
les joints se creusent.
