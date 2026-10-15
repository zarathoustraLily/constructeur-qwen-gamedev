# Tokyo · étape 004 · Fenêtres coulissantes en aluminium

**Pistes : Building et Shader.** Les baies étaient des trous. Chacune reçoit une fenêtre :
côté maillage, un simple rectangle ; côté shader, tout le reste. Le dormant, les deux vantaux
qui se croisent et le vitrage sont dessinés, pas modelés.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Pour régler l'immeuble, ouvrir
`{NAME}.tscn` et changer une variable du nœud racine : il y en a une de plus, `frame_color`.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Le shader `…_fenetre.gdshader` est nouveau :
c'est lui qu'il faut lire en entier.

## Ce qu'on a fait, dans l'ordre

### 1. Poser un rectangle par baie : `panel()`

Dans `_build_level()`, deux lignes de plus :

```gdscript
		var center: Vector3 = Vector3(x, base_y + sill_height + 0.5 * opening.y, -WINDOW_RECESS)
		_mesh.panel(opening, Transform3D(Basis.IDENTITY, center), _materials.window)
```

`panel(taille, repère, matériau)` pose un rectangle vertical. Le repère dit où est son centre
et vers où il regarde : `Basis.IDENTITY`, c'est face à `+Z`, la rue. Le rectangle n'est en
retrait que de 10 cm (`WINDOW_RECESS`) : une fenêtre d'aluminium est posée presque au nu du
mur, là où une fenêtre parisienne s'enfonce de plus de 20 cm dans la pierre.

### 2. Un rectangle instancié, pas dix-huit maillages

`panel()` ne fabrique pas de triangles. Il note une position et une taille. À la fin,
`commit()` crée un seul `MultiMesh` par matériau : le même carré d'un mètre de côté, dessiné
dix-huit fois, chaque fois avec sa propre matrice (position, orientation, échelle). Pour la
carte graphique, c'est un seul appel de dessin.

Deux raisons de faire ainsi :

- ce rectangle a des coordonnées UV, de (0, 0) en haut à gauche à (1, 1) en bas à droite. Le
  shader de fenêtre en a besoin, contrairement au carrelage ;
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

Les deux premières colonnes de `MODEL_MATRIX` sont les axes X et Y de l'instance ; leur
longueur est l'échelle. `flat` veut dire que la valeur n'est pas fondue entre les sommets :
elle est la même sur tout le rectangle.

Dans `fragment()`, on en tire des coordonnées en mètres, origine en bas à gauche :

```glsl
	vec2 q = vec2(UV.x * w, (1.0 - UV.y) * h);
```

Aucun paramètre de dimension n'est à régler : une fenêtre de 1,80 m et une de 3 m utilisent
le même matériau, et leurs profilés ont la même largeur.

### 4. Dessiner la menuiserie par une distance

Même principe que les joints du carrelage : on ne teste pas « suis-je dans l'aluminium ? »,
on calcule une distance. `inside` est positive dans le verre, négative dans le métal.

1. On part de la distance au bord du rectangle : `edge`.
2. On compte les vantaux : deux, ou quatre si la baie dépasse 2,40 m de large.
3. On cherche dans quel vantail est le pixel avec `floor()`, comme on cherchait son carreau.
4. `inside` est la plus petite distance aux quatre bords du vantail.
5. `inside = min(inside, edge - frame_width)` ajoute le dormant, tout autour.

```glsl
	float sashes = w > four_sash_width ? 4.0 : 2.0;
	float sash_span = (w - 2.0 * frame_width) / sashes;
	float sash = clamp(floor((q.x - frame_width) / sash_span), 0.0, sashes - 1.0);
	float lx = (q.x - frame_width) - sash * sash_span;
```

Puis une seule ligne transforme cette distance en masque :

```glsl
	float glass_cover = pc_step(0.0, inside, footprint);
```

Il vaut 1 sur le verre et 0 sur l'aluminium, avec un bord large d'un pixel.

### 5. Ce qui fait une fenêtre coulissante

Trois détails, tous dans le calcul de `inside` :

- **les montants qui se croisent.** Un vantail coulisse devant son voisin. Là où ils se
  croisent, leurs deux montants se recouvrent : on n'en voit qu'un, à peine plus large qu'un
  montant seul. C'est le rôle de `left_stile` et `right_stile`, qui valent `sash_width` contre
  le dormant et `0.65 * sash_width` de chaque côté d'un croisement ;
- **la traverse basse**, qui porte les roulettes, est plus haute que celle du haut :
  `y0 = frame_width + 1.6 * sash_width` ;
- **la traverse de plus** d'une porte-fenêtre, à hauteur de main. Elle n'apparaît que si le
  rectangle dépasse 1,75 m de haut. On ne la verra qu'à l'étape 007, avec les balcons.

### 6. Deux matières dans un seul shader

`glass_cover` sert à tout mélanger : la couleur, le métal, la brillance, le reflet, la normale.

```glsl
	ALBEDO = pc_color_out(mix(frame_albedo, pc_color_in(glass_color), glass_cover));
	METALLIC = 0.6 * (1.0 - glass_cover);
	ROUGHNESS = mix(0.4, glass_roughness, glass_cover);
	SPECULAR = mix(0.5, 0.85, glass_cover);
```

L'aluminium anodisé est un métal satiné : `METALLIC` vaut 0,6 sur les profilés, 0 sur le
verre. Le verre est sombre et très lisse, ce qui suffit pour que le moteur y fasse apparaître
le reflet du ciel. Il n'y a encore rien derrière la vitre : c'est l'étape suivante.

Le profilé dépasse du verre d'un centimètre. On ne le modèle pas : au bord, `pc_bump()`
penche la normale.

### 7. Côté matériaux

Le script des matériaux charge le nouveau shader et fabrique `window`, avec la teinte de
l'aluminium pour seul réglage.

## Ce qu'il faut retenir

1. Un détail plat et répété ne se modèle pas : un rectangle et un shader suffisent.
2. Les rectangles identiques s'instancient : un `MultiMesh`, un appel de dessin.
3. Un shader peut lire la taille de son objet dans `MODEL_MATRIX`.
4. Une distance signée, puis un masque : c'est la recette de tout dessin dans un shader.

## À essayer

- `frame_color` : un bronze (0,30 ; 0,25 ; 0,20), puis un noir.
- `bay_width` à 3 puis `window_width` à 2,6 : au-delà de 2,40 m de large, la fenêtre passe à
  quatre vantaux.
- Dans le shader : `sash_width` à 0,06.
- Dans le shader, écrire `ALBEDO = vec3(inside * 5.0);` à la fin : on voit la distance.
{TWIN}
## Étape suivante

005 : une pièce derrière chaque vitre, sans un seul triangle de plus, et la nuit.
