# Paris · étape 002 · Pierre de taille : assises et joints

**Piste : Shader.** Le maillage ne change pas. On remplace la couleur unie du mur par un motif
que la carte graphique calcule pixel par pixel : des assises de pierre et leurs joints. Aucune
image n'est chargée.

## Ouvrir le projet

Comme à l'étape 001 : importer `project.godot` dans Godot 4.7.2, puis F5. Pour régler
l'immeuble, ouvrir `{NAME}.tscn` et changer une variable du nœud racine.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Trois fichiers sont à lire, dans cet ordre :
le script de l'immeuble, celui des matériaux, puis le shader, où est la leçon.

## Ce qu'on a fait, dans l'ordre

### 1. Ranger les fonctions de maillage dans `1_core`

À l'étape 001, le script contenait `_add_triangle`, `_add_quad`, `_add_box` et `_commit`.
Ces fonctions ne savent rien d'un immeuble : elles serviraient telles quelles à un lampadaire.
Elles n'ont donc rien à faire dans `6_assets/…/Building/`. Elles sont maintenant dans
`1_core/procedural/mesh_builder.gd`, le dossier des mécanismes génériques.

Dans le script de l'immeuble, cela donne trois changements :

```gdscript
const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")   # on déclare l'outil

_mesh = MeshBuilder.new()                 # dans rebuild() : un outil neuf à chaque construction
_mesh.box(taille, centre, materiau)       # au lieu de _add_box(surface, taille, centre)
_mesh.commit(_root)                       # à la fin : un maillage par matériau
```

L'outil tient lui-même un `SurfaceTool` par matériau. On lui dit « cette boîte est en
pierre », il la range avec les autres pierres. C'est pour cela que les matériaux sont créés
**avant** la géométrie.

`mesh_builder.gd` contient déjà tout ce dont les étapes suivantes auront besoin (profils
extrudés, rectangles instanciés). On ne s'en sert pas encore : à cette étape, seules `box()`
et `commit()` comptent.

### 2. Un script pour les matériaux

La géométrie et la matière sont deux métiers : le script de l'immeuble dit **où** est la
pierre, celui des matériaux dit à quoi elle **ressemble**. D'où un second fichier,
`…_materiaux.gd`. L'immeuble s'en sert en trois temps :

```gdscript
_materials = Materials.new()
_materials.stone_color = stone_color     # 1. on règle
_materials.build()                       # 2. on fabrique
_mesh.box(taille, centre, _materials.stone)   # 3. on s'en sert
```

Dans `build()`, un `ShaderMaterial` est créé : un shader, plus ses réglages.

```gdscript
stone = _shader_material(STONE_SHADER, {
	"stone_color": stone_color,
})
```

Chaque clé du dictionnaire est le nom d'un `uniform` du fichier `.gdshader`. C'est le pont
entre les deux mondes : une variable du script, réglable dans l'inspecteur, devient un
paramètre du shader. Le nom doit être exactement le même des deux côtés.

### 3. Écrire le shader

Un shader `spatial` a trois parties :

- les `uniform` : ses réglages ;
- `vertex()` : exécutée une fois par sommet ;
- `fragment()` : exécutée une fois par pixel. Elle doit remplir `ALBEDO` (la couleur) et
  `ROUGHNESS` (mat ou brillant). L'éclairage est ensuite calculé par le moteur.

#### 3.1 Transmettre la position : `vertex()`

```glsl
varying vec3 v_pos;
varying vec3 v_nrm;

void vertex() {
	v_pos = VERTEX;
	v_nrm = NORMAL;
}
```

Un `varying` est une valeur écrite à chaque sommet et reçue par chaque pixel, fondue entre les
sommets du triangle. Ici, chaque pixel reçoit donc sa position dans l'immeuble, en mètres.
C'est tout ce dont le motif a besoin. Il n'y a pas de coordonnées UV.

#### 3.2 Des coordonnées de mur : `pc_face_frame()`

Un pixel a une position en 3D ; un motif de mur se dessine en 2D. `pc_face_frame()` fabrique,
à partir de la normale de la face, deux axes : `t` le long du mur, `b` vers le haut. Projeter
la position sur ces axes donne `u` et `v`, en mètres, quelle que soit l'orientation du mur.

#### 3.3 Une grille avec `floor()`

```glsl
float row = floor(v / course_height);      // numéro de l'assise
float vl = v - row * course_height;        // position dans l'assise, de 0 à course_height
float dy = min(vl, course_height - vl);    // distance au joint horizontal le plus proche
```

C'est la recette de tous les motifs répétés. On divise par la taille d'une case : la partie
entière est le numéro de la case, le reste est la position dedans. Même chose en largeur pour
les blocs, avec un décalage d'un demi-bloc une assise sur deux.

#### 3.4 Le joint, par une distance

On ne teste pas « suis-je dans un joint ? ». On mesure `dx` et `dy`, les distances au joint le
plus proche, puis on demande à `pc_band()` de les transformer en un masque entre 0 et 1.

#### 3.5 Filtrer : `fwidth()`

Une texture a des versions réduites toutes prêtes pour être vue de loin. Un motif calculé
n'en a pas : un joint plus fin qu'un pixel scintillerait. `fwidth(u)` dit de combien `u`
change d'un pixel au suivant, c'est-à-dire la taille d'un pixel sur le mur. `pc_band()` s'en
sert pour donner au joint un bord large d'un pixel : de loin, il s'estompe proprement.

#### 3.6 La couleur

```glsl
vec3 col = pc_color_in(stone_color);
col = mix(col, pc_color_in(joint_color), joint_mask);
ALBEDO = pc_color_out(col);
```

`mix(a, b, m)` va de `a` à `b` quand `m` va de 0 à 1. `pc_color_in()` et `pc_color_out()`
encadrent tous les calculs de couleur : ils font que le shader donne la même image avec les
trois moteurs de rendu de Godot. L'explication est en tête de `procedural_commun.gdshaderinc`.

### 4. Le fichier commun `procedural_commun.gdshaderinc`

Un `.gdshaderinc` ne dessine rien. C'est une boîte à outils que chaque shader recopie chez lui
avec `#include`. Il est rangé un cran au-dessus de `DECORS/Building/` parce qu'il servira à
tous les décors. À cette étape, on n'en lit que les parties marquées « ÉTAPE 002 ».

## Ce qu'il faut retenir

1. Ce qui est générique monte dans `1_core` ; ce qui est propre à l'immeuble reste dans `6_assets`.
2. La géométrie et la matière ont chacune leur script.
3. Un motif procédural part d'une position en mètres, pas d'une image.
4. `floor()` fait la grille ; une distance fait le dessin ; `fwidth()` le filtre.

## À essayer

- Dans l'inspecteur : changer `stone_color`.
- Dans le shader : remplacer la ligne `ALBEDO` par
  `ALBEDO = vec3(fract(v / course_height));`. On voit la grille nue, en dégradés.
- Dans le shader : valeur par défaut de `joint_width` à 0,03, puis reculer la caméra. Le joint
  s'adoucit avec la distance.
- Dans le shader : valeur par défaut de `course_height` à 0,6. L'immeuble se met à jour dans
  l'éditeur dès l'enregistrement.
{TWIN}
## Étape suivante

003 : le même shader apprend le hasard. Chaque bloc aura sa teinte, le mur se salira, les
joints prendront du relief.
