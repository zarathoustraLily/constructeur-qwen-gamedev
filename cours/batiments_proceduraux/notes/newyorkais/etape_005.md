# New York · étape 005 · Une pièce derrière la vitre, bureaux la nuit

**Piste : Shader.** Derrière chaque vitre, on fait apparaître un bureau : son faux plafond à
dalles et ses luminaires encastrés, sa moquette, ses cloisons basses, ses classeurs, la porte
du couloir au fond, le store à demi baissé. Il n'existe pas : aucun triangle de plus. La nuit,
les étages s'allument un par un.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Appuyer sur **N** pour passer du jour à la
nuit. S'approcher d'une fenêtre et se déplacer devant elle : la pièce a de la profondeur.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Tout se passe dans `…_fenetre.gdshader` :
chercher « NOUVEAU ». Les scripts ne font que transmettre les cotes des étages, le jour et la
nuit.

## Ce qu'on a fait, dans l'ordre

### 1. L'idée : prolonger le regard

Une fenêtre est un rectangle plat. Pour chaque pixel de ce rectangle, on connaît la direction
du regard. On prolonge ce regard derrière la vitre, dans une boîte imaginaire, et on cherche la
paroi qu'il touche : le fond, un côté, le sol ou le plafond. Il ne reste qu'à colorier le pixel
de la couleur de cette paroi à cet endroit. La technique s'appelle « interior mapping ».

### 2. Le repère de la fenêtre

Il faut exprimer le regard dans le repère de la fenêtre : `x` vers sa droite, `y` vers le haut,
`z` vers l'extérieur. `vertex()` amène donc les axes de l'instance dans l'espace de la caméra,
où le moteur donne le regard (`VIEW`) :

```glsl
	v_axis_x = normalize((VIEW_MATRIX * vec4(MODEL_MATRIX[0].xyz, 0.0)).xyz);
	v_axis_y = normalize((VIEW_MATRIX * vec4(MODEL_MATRIX[1].xyz, 0.0)).xyz);
```

Dans `fragment()`, trois produits scalaires donnent la direction du rayon dans ce repère :

```glsl
	vec3 d = -vec3(dot(view_dir, v_axis_x), dot(view_dir, v_axis_y), dot(view_dir, axis_z));
	d.z = min(d.z, -0.03);
```

La seconde ligne empêche le rayon d'être rasant : on va diviser par `d.z`.

### 3. La boîte : un bureau de 1916

La pièce a ses cotes, que le script donne au shader par les matériaux : la hauteur d'un étage,
celle de l'allège, la largeur d'une travée.

```glsl
	float sill = sill_height;
	float room_h = floor_height - plenum;
	float depth = room_depth * (0.6 + 0.4 * r3);
	float span = 1.0 + floor(r4 * 3.0);
	float place = floor(r5 * span);
```

- le sol est sous l'allège, à `-sill` dans le repère de la fenêtre ;
- le plafond est un faux plafond : 60 cm sous la dalle du dessus (`plenum`) passent les gaines ;
- la profondeur est tirée, jusqu'à 8,5 m : 28 pieds, la profondeur d'un bureau de l'époque,
  de la fenêtre au couloir. Au-delà, la lumière du jour n'arrive plus ;
- un bureau fait une, deux ou trois travées de large (`span`), et la fenêtre est dans l'une
  d'elles (`place`).

### 4. Toucher une paroi : le rayon et la boîte

La boîte a six parois, deux par axe. Sur chaque axe, le rayon ne peut toucher que celle vers
laquelle il va. On calcule la distance jusqu'à chacune des trois, et la plus courte gagne :

```glsl
	float tx = abs(d.x) > 0.00001 ? ((d.x > 0.0 ? x1 : x0) - origin.x) / d.x : 100000.0;
	float ty = abs(d.y) > 0.00001 ? ((d.y > 0.0 ? ceil_y : floor_y) - origin.y) / d.y : 100000.0;
	float tz = -depth / d.z;
	float t_hit = min(tx, min(ty, tz));
	vec3 hit = origin + d * t_hit;
```

`hit` est le point touché, en mètres, dans le repère de la fenêtre. Le shader range ensuite ce
qu'il a touché dans quatre valeurs : `face` (0 le fond, 1 un côté, 2 le sol, 3 le plafond), `m`
(la position sur cette paroi, en mètres), `extent` (sa taille), et `sky_fill`, la part de jour
qu'elle reçoit.

### 5. Peindre un bureau : `office_surface()`

Une fonction reçoit cette description et renvoie une couleur. Séparer « quelle paroi » de « de
quelle couleur » rendra la suite facile : une autre sorte de pièce sera une autre fonction, avec
les mêmes arguments.

Tout y est fait de deux briques, définies juste au-dessus :

- `rect()` : le masque d'un rectangle à bords adoucis. Une porte, un classeur, un tableau : des
  rectangles ;
- `grid_lines()` : un quadrillage qui s'efface quand il devient plus fin que le pixel.

Le plafond est le plus important : depuis la rue, on regarde les étages par en dessous.

```glsl
		vec3 col = vec3(0.82, 0.82, 0.80) * (1.0 - 0.12 * grid_lines(m, vec2(0.61, 1.22), 0.006, soft));
		vec2 cell = vec2(2.44, 3.66);
		fixture = rect(mod(m, cell), vec2(0.61, 1.83), vec2(0.27, 0.57), soft);
```

Des dalles de 2 pieds sur 4, et un luminaire encastré de la taille d'une dalle, répété par
`mod()` dans chaque case. `fixture` sort de la fonction par un argument `out` : c'est le masque
des luminaires, dont l'éclairage aura besoin. Au sol, une moquette en dalles ; au fond, la
cloison du couloir et sa porte de bois à vitre dépolie ; sur le côté, une rangée de classeurs
métalliques et un tableau.

### 6. Les cloisons basses : un plan de plus

Un plan parallèle à la vitre, à une distance tirée, haut de 1,35 m et coupé d'une allée tous
les 3,60 m. S'il est touché avant la paroi, il la cache :

```glsl
	float t_part = -(2.2 + 1.6 * r7) / d.z;
	vec3 part_hit = origin + d * t_part;
	float part_y = part_hit.y - floor_y;
	float aisle = mod(part_hit.x - x0 + 3.6 * r8, 3.6);
	if (t_part < t_hit && part_y > 0.0 && part_y < 1.35 && aisle > 1.2) {
```

C'est toute la méthode : la boîte donne le fond, et chaque objet de plus est un plan, avec sa
découpe.

### 7. Éclairer la pièce soi-même

Le moteur n'éclaire pas cette pièce : elle n'a pas de géométrie. On calcule donc sa lumière
dans le shader. D'abord : la pièce est-elle allumée ?

```glsl
	float floor_key = floor(v_key.y / floor_height);
	float floor_lit = step(pc_hash2(vec2(floor_key, 7.0 + seed)), mix(floor_lit_day, floor_lit_night, night));
	float lit = floor_lit > 0.5 ? step(r9, 0.9) : step(r9, 0.05);
```

Le modèle choisi : la nuit, une tour de bureaux ne s'allume pas fenêtre par fenêtre, mais par
étages entiers, ceux où l'on travaille encore ou ceux où passe le ménage. On tire donc d'abord
l'étage : son numéro se déduit de la hauteur de la fenêtre. Dans un étage allumé, neuf pièces
sur dix le sont ; dans un étage éteint, une sur vingt.

Puis la lumière : celle du jour, qui entre par la fenêtre et s'éteint avec la profondeur, et
celle des luminaires, à peu près égale partout.

```glsl
	float depth_fade = exp(hit.z / 3.4);
	vec3 day_light = vec3(0.92, 0.96, 1.0) * day * sky_fill * (0.22 + 0.78 * depth_fade) * 0.6;
	float lamp_power = lamp_energy * lit * mix(0.5, 1.0, night);
	vec3 lamp_light = light_tint * lamp_power * (0.48 + 0.3 * max(surface_normal.y, 0.0));
```

Les luminaires eux-mêmes sont peints très clairs s'ils sont allumés :

```glsl
	interior = mix(interior, light_tint * (0.25 * day + 2.4 * lamp_power), fixture);
```

### 8. Le store à enrouleur

Six centimètres derrière la vitre, une toile tendue, descendue plus ou moins bas depuis le haut.
Elle laisse passer la lumière, pas les formes : le jour, elle est éclairée du dehors ; la nuit,
de la pièce, si la pièce est allumée.

```glsl
		float low = h * mix(0.3, 0.95, r11);
```

Le plus souvent, le store ne cache que le haut de la vitre. Une barre de lestage sombre borde
son bas. Plus d'une fenêtre sur deux en a un (`shades`, 0,55) : de loin, ce sont ces bandes
claires en haut des fenêtres qui font la façade d'une tour de bureaux.

### 9. Le reflet : ce qui est réfléchi ne traverse pas

```glsl
	float fresnel = f0 + (1.0 - f0) * pow(1.0 - n_dot_v, 5.0);
	vec3 tint = pc_color_in(glass_tint) * (1.0 - fresnel);
	vec3 transmitted = interior * mix(tint, tint * tint, double_glass);
```

Plus le regard est rasant, plus la vitre renvoie le ciel et moins on voit la pièce. C'est la loi
de Fresnel, dans la forme de Schlick. Là où les deux châssis se croisent, on regarde à travers
deux vitres : la teinte compte deux fois.

La pièce sort par `EMISSION`, et non par `ALBEDO` : elle a déjà sa lumière, le moteur ne doit
pas l'éclairer une seconde fois. Le verre n'a plus de couleur propre ; le reflet du ciel est
ajouté par le moteur.

```glsl
	ALBEDO = pc_color_out(mix(frame_albedo, vec3(0.0), glass_cover));
	EMISSION = pc_color_out(transmitted * glass_cover);
```

### 10. La nuit, côté scripts

La touche N de la visite appelle `set_night()` sur la tour, qui le transmet à ses matériaux,
qui règlent l'uniforme `night` du shader. La tour garde la valeur dans `_night` pour la
redonner après une reconstruction.

```gdscript
func set_night(value: float) -> void:
	_night = value
	if _materials != null:
		_materials.set_night(_night)
```

## Ce qu'il faut retenir

1. Une pièce derrière une vitre peut n'être qu'un calcul : un rayon, une boîte, et des plans.
2. Séparer « quelle paroi est touchée » de « de quelle couleur elle est ».
3. Ce qui n'a pas de géométrie doit calculer sa propre lumière, et sortir par `EMISSION`.
4. Allumer par étages, puis par pièces : la règle du tirage fait le réalisme de la nuit.

## À essayer

- N, puis reculer : compter les étages allumés.
- Dans le shader : `floor_lit_night` à 1, puis à 0.
- `shades` à 1 (un store partout), puis à 0.
- `room_depth` à 3, puis à 15 : une pièce trop profonde n'a plus de jour au fond.
- `tube_color` : un jaune chaud, pour voir ce que la teinte des luminaires apporte.
- `sill_height` de la tour à 0,3 : le sol des pièces suit.

## Sources

- La technique vient de Joost van Dongen, « Interior Mapping: A new technique for rendering
  realistic buildings », conférence Computer Graphics International, 2008.
- La profondeur des bureaux, 28 pieds de la fenêtre au couloir : The Skyscraper Museum,
  « Impact of 1916 Zoning ».
{TWIN}
## Étape suivante

006 : les gradins. Le règlement de zonage de 1916 sculpte la tour : elle monte droit sur la rue,
puis recule par gradins, et une tour plus mince peut monter sans limite.
