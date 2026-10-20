# Tokyo · étape 005 · Une pièce derrière la vitre, bureaux éclairés

**Piste : Shader.** Derrière chaque vitre, on fait apparaître une pièce : ici un bureau, avec
son plafond à dalles, ses tubes fluorescents, ses armoires de métal et son store à lames.
Elle n'existe pas : aucun triangle de plus. La nuit, une partie des bureaux s'allume.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Appuyer sur **N** pour passer du jour à
la nuit. S'approcher d'une fenêtre et se déplacer devant elle : la pièce a de la profondeur.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Tout se passe dans `…_fenetre.gdshader` :
chercher « NOUVEAU ». Les scripts ne font que transmettre le jour et la nuit.

## Ce qu'on a fait, dans l'ordre

### 1. L'idée : prolonger le regard

Une fenêtre est un rectangle plat. Pour chaque pixel de ce rectangle, on connaît la direction
du regard. On prolonge ce regard derrière la vitre, dans une boîte imaginaire, et on cherche
la paroi qu'il touche : le fond, un côté, le sol ou le plafond. Il ne reste qu'à colorier le
pixel de la couleur de cette paroi à cet endroit. La technique s'appelle « interior mapping ».

### 2. Le repère de la fenêtre

Il faut exprimer le regard dans le repère de la fenêtre : `x` vers sa droite, `y` vers le
haut, `z` vers l'extérieur. `vertex()` amène donc les axes de l'instance dans l'espace de la
caméra, où le moteur donne le regard (`VIEW`) :

```glsl
	v_axis_x = normalize((VIEW_MATRIX * vec4(MODEL_MATRIX[0].xyz, 0.0)).xyz);
	v_axis_y = normalize((VIEW_MATRIX * vec4(MODEL_MATRIX[1].xyz, 0.0)).xyz);
	v_room_key = MODEL_MATRIX[3].xyz;
```

La troisième ligne garde la position de la fenêtre : elle servira de numéro de tirage.

Dans `fragment()`, trois produits scalaires donnent la direction du rayon dans ce repère :

```glsl
	vec3 d = -vec3(dot(view_dir, v_axis_x), dot(view_dir, v_axis_y), dot(view_dir, axis_z));
	d.z = min(d.z, -0.03);
```

La seconde ligne empêche le rayon d'être rasant : on va diviser par `d.z`.

### 3. Toucher une paroi : le rayon et la boîte

La boîte a six parois, deux par axe. Sur chaque axe, le rayon ne peut toucher que celle vers
laquelle il va. On calcule la distance jusqu'à chacune des trois, et la plus courte gagne :

```glsl
	float tx = abs(d.x) > 0.00001 ? ((d.x > 0.0 ? x1 : x0) - origin.x) / d.x : 100000.0;
	float ty = abs(d.y) > 0.00001 ? ((d.y > 0.0 ? ceil_y : floor_y) - origin.y) / d.y : 100000.0;
	float tz = -depth / d.z;
	float t_hit = min(tx, min(ty, tz));
	vec3 hit = origin + d * t_hit;
```

`hit` est le point touché, en mètres, dans le repère de la fenêtre. Le sol est à `-sill` :
la hauteur de l'allège. Le shader la reçoit par l'uniforme `sill_height`, que le script des
matériaux règle d'après la variable du même nom de l'immeuble.

### 4. Décrire la paroi, puis la peindre

Le shader range d'abord ce qu'il a touché dans quatre valeurs :

```glsl
	int face;
	vec2 m;
	vec2 extent;
```

`face` vaut 0 pour le mur du fond, 1 pour un mur latéral, 2 pour le sol, 3 pour le plafond.
`m` est la position sur cette paroi, en mètres ; `extent`, la taille de la paroi.

Puis une fonction peint : elle reçoit cette description et renvoie une couleur.

```glsl
	vec3 albedo = office_surface(face, m, extent, soft, r4, fixture);
```

Séparer « quelle paroi » de « de quelle couleur » rendra l'étape 006 facile : une autre sorte
de pièce sera une autre fonction, avec les mêmes arguments.

### 5. Peindre un bureau : `office_surface()`

Tout y est fait de deux briques, définies juste au-dessus :

- `rect()` : le masque d'un rectangle à bords adoucis. Une armoire, une porte, un tableau
  blanc : des rectangles ;
- `grid_lines()` : un quadrillage qui s'efface quand il devient plus fin que le pixel. Les
  dalles du plafond, les portes des armoires.

Le plafond porte les luminaires, un toutes les trois dalles :

```glsl
		vec2 cell = vec2(1.8, 1.8);
		vec2 in_cell = (fract(m / cell) - 0.5) * cell;
		fixture = rect(in_cell, vec2(0.0), vec2(0.6, 0.14), soft);
```

`fract(m / cell)` répète le même dessin dans chaque case de 1,80 m : c'est `floor()` vu de
l'autre côté. `fixture` sort de la fonction par un argument `out` : c'est le masque des
tubes, dont l'éclairage aura besoin.

### 6. Une pièce par fenêtre

```glsl
	float r0 = pc_hash3(v_room_key * 8.0 + vec3(seed * 17.0, seed * 5.0, seed * 3.0));
	float r1 = pc_rehash(r0, 1.0);
```

Le hachage de l'étape 003, appliqué à la position de la fenêtre. Les tirages suivants, tous
tirés de `r0`, règlent la largeur de la pièce, sa profondeur, la place des armoires, le
store, et si la lumière est allumée. Deux fenêtres voisines n'ont pas le même bureau.

### 7. Éclairer la pièce soi-même

Le moteur n'éclaire pas cette pièce : elle n'a pas de géométrie. On calcule donc sa lumière
dans le shader.

```glsl
	float lit = step(r0, mix(office_lit_day, office_lit_night, night));
	float lamp_power = lamp_energy * lit * mix(0.5, 1.0, night);
	vec3 lamp_light = light_tint * lamp_power * (0.48 + 0.3 * max(surface_normal.y, 0.0));
```

Une pièce est allumée si son tirage tombe sous la part de pièces allumées. Un bureau
s'éclaire même en plein jour : `office_lit_day` vaut 0,45.

Des tubes au plafond éclairent toute la pièce à peu près également. Il n'y a donc pas de
lampe ponctuelle, seulement un peu plus de lumière sur ce qui regarde vers le haut. Les tubes
eux-mêmes sont peints très clairs s'ils sont allumés :

```glsl
	interior = mix(interior, light_tint * (0.25 * day + 2.4 * lamp_power), fixture);
```

Depuis la rue, on regarde les étages par en dessous : c'est surtout le plafond qu'on voit.
Ce sont ces rectangles blancs qui font reconnaître un bureau.

### 8. Le store à lames : un plan de plus

Huit centimètres derrière la vitre, un plan de plus. S'il est touché avant la paroi, il la
cache.

```glsl
		float lowered = mix(0.25, 1.0, r8);
		float closed = mix(0.4, 0.92, r5);
		float in_slat = fract(c.y / pitch);
		float slat_fade = 1.0 - smoothstep(0.25, 0.9, footprint / pitch);
		float body = mix(closed, step(in_slat, closed), slat_fade);
```

Le store est plus ou moins baissé (`lowered`), ses lames plus ou moins fermées (`closed`). De
près, on voit chaque lame et le jour entre elles. De loin, une lame de 25 mm est plus fine que
le pixel : on prend la moyenne, qui est la part fermée. Toujours le même filtrage.

### 9. Le reflet : ce qui est réfléchi ne traverse pas

```glsl
	float fresnel = f0 + (1.0 - f0) * pow(1.0 - n_dot_v, 5.0);
	vec3 transmitted = interior * pc_color_in(glass_tint) * (1.0 - fresnel) * frame_shadow;
```

Plus le regard est rasant, plus la vitre renvoie le ciel et moins on voit la pièce. C'est la
loi de Fresnel, dans la forme de Schlick.

La pièce sort par `EMISSION`, et non par `ALBEDO` : elle a déjà sa lumière, le moteur ne doit
pas l'éclairer une seconde fois. Le verre n'a plus de couleur propre ; le reflet du ciel est
ajouté par le moteur.

```glsl
	ALBEDO = pc_color_out(mix(frame_albedo, vec3(0.0), glass_cover));
	EMISSION = pc_color_out(transmitted * glass_cover);
```

### 10. La nuit, côté scripts

La touche N de la visite appelle `set_night()` sur l'immeuble, qui le transmet à ses
matériaux, qui règlent l'uniforme `night` du shader. L'immeuble garde la valeur dans
`_night` pour la redonner après une reconstruction.

```gdscript
func set_night(value: float) -> void:
	_night = value
	if _materials != null:
		_materials.set_night(_night)
```

## Ce qu'il faut retenir

1. Une pièce derrière une vitre peut n'être qu'un calcul : un rayon, une boîte.
2. Séparer « quelle paroi est touchée » de « de quelle couleur elle est ».
3. Ce qui n'a pas de géométrie doit calculer sa propre lumière, et sortir par `EMISSION`.
4. Un plan de plus devant la boîte suffit pour un store ou un rideau.
5. La position d'une instance est un bon numéro de tirage.

## À essayer

- N, puis s'approcher d'un bureau allumé et regarder son plafond.
- Dans le shader : `office_lit_night` à 1, puis à 0.
- `dressing` à 1 (un store partout), puis à 0.
- `room_depth` à 2, puis à 10.
- `tube_color` : un jaune chaud, pour voir ce que la teinte des tubes apporte.
- `sill_height` de l'immeuble à 0,3 : le sol des pièces suit.

## Source

La technique vient de Joost van Dongen, « Interior Mapping: A new technique for rendering
realistic buildings », conférence Computer Graphics International, 2008.
{TWIN}
## Étape suivante

006 : des niveaux différents. Un rez-de-chaussée haut, des bureaux, des logements, une cage
d'escalier. Et, pour le shader, une pièce différente selon l'étage.
