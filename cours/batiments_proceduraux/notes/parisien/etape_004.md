# Paris · étape 004 · Fenêtres à petits bois

**Pistes : Building et Shader.** Les baies étaient des trous noirs. Chacune reçoit une
fenêtre : côté maillage, un simple rectangle ; côté shader, tout le reste. Dormant, vantaux,
petits bois et vitrage sont dessinés, pas modelés.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Pour régler l'immeuble, ouvrir
`{NAME}.tscn` et changer une variable du nœud racine : il y en a une de plus, `frame_color`.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Le shader `…_fenetre.gdshader` est nouveau :
c'est lui qu'il faut lire en entier.

## Ce qu'on a fait, dans l'ordre

### 1. Poser un rectangle par baie : `panel()`

Dans `_build_level()`, cinq lignes de plus :

```gdscript
var center: Vector3 = Vector3(x, base_y + sill_height + 0.5 * opening.y, -WINDOW_RECESS)
_mesh.panel(opening, Transform3D(Basis.IDENTITY, center), _materials.window)
```

`panel(taille, repère, matériau)` pose un rectangle vertical. Le repère dit où est son centre
et vers où il regarde : `Basis.IDENTITY`, c'est face à `+Z`, la rue. Le rectangle est en
retrait de 22 cm (`WINDOW_RECESS`) : il est au fond de la baie, et l'épaisseur du mur lui fait
de l'ombre.

### 2. Un rectangle instancié, pas vingt-cinq maillages

`panel()` ne fabrique pas de triangles. Il note une position et une taille. À la fin,
`commit()` crée un seul `MultiMesh` par matériau : le même carré d'un mètre de côté, dessiné
vingt-cinq fois, chaque fois avec sa propre matrice (position, orientation, échelle). Pour la
carte graphique, c'est un seul appel de dessin.

Deux raisons de faire ainsi :

- ce rectangle a des coordonnées UV, de (0, 0) en haut à gauche à (1, 1) en bas à droite. Le
  shader de fenêtre en a besoin, contrairement à la pierre ;
- chaque fenêtre garde sa matrice, donc sa position : l'étape 005 s'en servira pour donner une
  pièce différente à chacune.

### 3. Retrouver la taille de la fenêtre dans le shader

Le carré de base mesure un mètre. Sa taille réelle est l'échelle de son instance, que le
shader lit dans sa matrice :

```glsl
varying flat vec2 v_size;

void vertex() {
	v_size = vec2(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz));
}
```

Les deux premières colonnes de `MODEL_MATRIX` sont les axes X et Y de l'instance ; leur longueur
est l'échelle. `flat` veut dire que la valeur n'est pas fondue entre les sommets : elle est la
même sur tout le rectangle.

Dans `fragment()`, on en tire des coordonnées en mètres, origine en bas à gauche :

```glsl
vec2 q = vec2(UV.x * w, (1.0 - UV.y) * h);
```

Aucun paramètre de dimension n'est à régler : une fenêtre de 1,30 m et une de 2 m utilisent
le même matériau, et leurs montants ont la même largeur.

### 4. Dessiner la menuiserie par une distance

Même principe que les joints de la pierre : on ne teste pas « suis-je dans le bois ? », on
calcule une distance. `inside` est positive dans le verre, négative dans le bois.

1. On part de la distance au bord du rectangle : `edge`.
2. On cherche dans quel vantail est le pixel, à gauche ou à droite du battement central.
3. On découpe le vantail en carreaux avec `floor()`, comme les assises.
4. `inside` est la plus petite distance aux quatre bords du carreau. Un petit bois n'existe
   qu'entre deux carreaux, d'où les tests `cy > 0.5` et `cy < rows - 1.5`.
5. `inside = min(inside, edge - frame_width)` ajoute le dormant, tout autour.

Puis une seule ligne transforme cette distance en masque :

```glsl
float glass_cover = pc_step(0.0, inside, footprint);   // 1 sur le verre, 0 sur le bois
```

### 5. Deux matières dans un seul shader

`glass_cover` sert à tout mélanger : la couleur, la brillance, le reflet, la normale.

```glsl
ALBEDO = pc_color_out(mix(frame_albedo, pc_color_in(glass_color), glass_cover));
ROUGHNESS = mix(0.45, glass_roughness, glass_cover);
SPECULAR = mix(0.5, 0.85, glass_cover);
```

Le bois est peint et un peu mat ; le verre est sombre et très lisse, ce qui suffit pour que le
moteur y fasse apparaître le reflet du ciel. Il n'y a encore rien derrière la vitre : c'est
l'étape suivante.

Le bois dépasse du verre d'un centimètre. On ne le modèle pas : au bord, `pc_bump()` penche
la normale, comme pour le grain de la pierre.

### 6. Côté matériaux

Le script des matériaux charge le nouveau shader et fabrique `window`, avec la teinte des
menuiseries pour seul réglage.

## Ce qu'il faut retenir

1. Un détail plat et répété ne se modèle pas : un rectangle et un shader suffisent.
2. Les rectangles identiques s'instancient : un `MultiMesh`, un appel de dessin.
3. Un shader peut lire la taille de son objet dans `MODEL_MATRIX`.
4. Une distance signée, puis un masque : c'est la recette de tout dessin dans un shader.

## À essayer

- `frame_color` : un gris anthracite (0,2 ; 0,22 ; 0,24).
- `window_width` à 2 : les montants gardent leur largeur, seuls les carreaux s'élargissent.
- Dans le shader : `pane_rows` à 4, `two_leaves` à `false`.
- Dans le shader, écrire `ALBEDO = vec3(inside * 5.0);` à la fin : on voit la distance.
{TWIN}
## Étape suivante

005 : une pièce derrière chaque vitre, sans un seul triangle de plus, et la nuit.
