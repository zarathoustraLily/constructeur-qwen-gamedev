# Tokyo · étape 007 · Balcons, garde-corps, climatiseurs

**Pistes : Building et Shader.** Les étages de logements reçoivent leur balcon. Il est en
creux : ce n'est pas une dalle qui dépasse, c'est le mur des fenêtres qui recule. Le
garde-corps reste au nu de la façade. Sur chaque balcon, un climatiseur. Un nouveau shader
dessine les barreaux, les panneaux et la grille du ventilateur.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Trois variables de plus dans le groupe
**Façade** : `balcony_depth`, `railing_style`, `ac_units`. Monter à hauteur des balcons avec
la touche E, et regarder l'ombre des barreaux sur la dalle.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Deux fichiers à lire : le script de
l'immeuble, où `_build_balcony()` est nouvelle, et `…_garde_corps.gdshader`, nouveau.

## Ce qu'on a fait, dans l'ordre

### 1. Pourquoi un balcon en creux

Quand la façade est à la limite de la parcelle, un balcon n'a pas la place d'avancer : il
déborderait sur la voie. La seule place pour lui est à l'intérieur du volume : le garde-corps
reste à l'alignement, et les fenêtres se retrouvent un mètre plus loin, dans l'ombre. D'où
les bandes horizontales sombres de beaucoup d'immeubles de logements japonais.

### 2. Un champ de plus dans `Level`

```gdscript
	## Profondeur du balcon en creux : le mur des fenêtres recule d'autant. 0 : pas de balcon.
	var recess: float = 0.0
```

`_make_levels()` le remplit pour les logements, et change leurs baies en portes-fenêtres :

```gdscript
			if balcony_depth > 0.0:
				# Avec un balcon : une porte-fenêtre, et le mur recule de la profondeur du balcon.
				level.recess = balcony_depth
				level.sill = SLAB_THICKNESS
				level.opening = Vector2(bay_width - 0.5, 2.0)
```

Une porte-fenêtre de 2 m dépasse 1,75 m : le shader de fenêtre lui ajoute tout seul sa
traverse à hauteur de main, prévue depuis l'étape 004.

### 3. Faire reculer le mur

Dans `_build_level()`, le mur et la vitre ne sont plus toujours au même endroit :

```gdscript
		var recess: float = 0.0 if is_core else level.recess
		var wall_z: float = -recess - 0.5 * WALL_DEPTH
		var glass_z: float = -recess - WINDOW_RECESS
```

La travée d'escalier ne recule pas : elle reste au nu de la façade, et ferme le balcon d'un
côté. Les quatre boîtes autour de chaque baie n'ont pas changé ; elles sont seulement posées
plus loin.

### 4. Le volume arrière suit chaque niveau

Jusqu'ici, une seule boîte fermait l'immeuble derrière la façade. Elle remplirait les
balcons. Chaque niveau a donc maintenant la sienne, qui commence derrière son propre mur :

```gdscript
func _build_back(level: Level, base_y: float) -> void:
	var width: float = get_facade_width()
	var front: float = level.recess + WALL_DEPTH
	var length: float = depth - front
	_box(Vector3(width, level.height, length), Vector3(0.0, base_y + 0.5 * level.height, -front - 0.5 * length), _materials.side)
```

Quand une pièce nouvelle entre dans un générateur, il faut souvent revoir une pièce ancienne
qui tenait par hasard.

### 5. Le balcon : `_build_balcony()`

Cinq pièces, toutes des boîtes sauf la dernière :

| Pièce | Rôle |
|---|---|
| La dalle | le sol. Son nez dépasse de 2 cm de la façade : une ligne d'ombre à chaque étage |
| La poutre de rive | ferme le haut du balcon, au nu de la façade |
| Deux murs d'aile | ferment les deux bouts |
| Le garde-corps | entre les murs d'aile, posé sur la dalle, haut de 1,10 m |

Le balcon court devant toutes les travées, sauf celle de l'escalier :

```gdscript
	var left: float = -0.5 * width + (bay_width if core == 0 else 0.0)
	var right: float = 0.5 * width - (bay_width if core == bay_count - 1 else 0.0)
```

La hauteur du garde-corps est une constante, `GUARD_HEIGHT`. Elle vient d'un règlement : le
texte d'application de la loi japonaise sur les normes de construction (article 126) demande
1,10 m au moins autour d'un toit-terrasse qui sert à l'évacuation. Le cours prend la même
hauteur pour les balcons.

### 6. Trois garde-corps, deux façons de les faire

```gdscript
	if style == RAILING_WALL:
		# Muret plein, du même revêtement que la façade, coiffé d'une lisse d'aluminium.
		_box(Vector3(guard.x, GUARD_HEIGHT, 0.12), Vector3(middle, guard_y, -0.06), _materials.facade)
		_box(Vector3(guard.x, 0.04, 0.16), Vector3(middle, guard_y + 0.5 * GUARD_HEIGHT + 0.02, -0.06), _materials.aluminium)
	else:
		# Barreaux ou panneaux : un rectangle instancié, et le shader fait le reste. La donnée
		# de l'instance lui dit quel motif dessiner.
		var motif: float = MOTIF_PANELS if style == RAILING_PANELS else MOTIF_BARS
		_panel(guard, Vector3(middle, guard_y, -0.04), _materials.railing, Color(motif, 0.0, 0.0, 0.0))
```

Le muret plein est une boîte, du même matériau que la façade : le carrelage continue dessus,
puisque le motif vient de la position. Les barreaux et les panneaux sont **un seul
rectangle**, quelle que soit la largeur du balcon. Modeler chaque barreau coûterait des
centaines de triangles par étage.

### 7. Le climatiseur

Une boîte posée sur la dalle, contre le mur, et un rectangle sur sa face avant :

```gdscript
		_box(unit, unit_center, _materials.appliance)
		_panel(Vector2(unit.x, unit.y), unit_center + Vector3(0.0, 0.0, 0.5 * unit.z + 0.004), _materials.railing, Color(MOTIF_FAN_GRILLE, 0.0, 0.0, 0.0))
```

Ce rectangle utilise le matériau des garde-corps, avec un autre motif : la grille ronde du
ventilateur. Garde-corps et grilles partent donc dans le même appel de dessin.

### 8. Dessiner avec une distance signée

Le shader `…_garde_corps.gdshader` applique la recette de l'étape 004, poussée plus loin.
Pour chaque pixel, il calcule sa distance au métal le plus proche : négative dans le métal,
positive dans le vide.

- une lisse horizontale : la distance à une droite, moins une demi-épaisseur ;
- un anneau de grille : la distance à un cercle ;
- réunir deux formes : le plus petit des deux nombres, `min()`.

```glsl
	float d = abs(p.y - (size.y - half_rail)) - half_rail;
	d = min(d, abs(p.y - 0.08) - 0.7 * half_rail);
	return min(d, min(along, module - along) - 0.8 * half_rail);
```

Trois lignes : la lisse haute, la lisse basse, un poteau à chaque limite de module.

### 9. Répéter un motif, et tomber juste

Les barreaux se répètent tous les 11 cm environ. « Environ », parce que leur nombre est
ajusté pour que le dernier tombe exactement sur un poteau :

```glsl
			float count = max(1.0, floor(module / bar_spacing + 0.5));
			float pitch = module / count;
			float bars = abs(fract(along / pitch + 0.5) - 0.5) * pitch - hw;
```

`floor(x + 0.5)` arrondit au plus proche. `fract()` ramène tous les barreaux à un seul : on
calcule la distance au barreau le plus proche, une fois, et elle vaut pour tous.

### 10. Découper le vide

```glsl
	ALPHA = max(step(0.5, solid), step(threshold, veil));
	ALPHA_SCISSOR_THRESHOLD = 0.5;
```

`ALPHA` vaut 0 ou 1, et un seuil : le pixel est gardé ou jeté. Ce n'est pas de la
transparence, qui demanderait de trier les objets. Le vide entre les barreaux ne porte donc
pas d'ombre : c'est la dentelle qu'on voit sur la dalle.

Le shader distingue deux sortes de métal. Les lisses et les poteaux (`structure`) ne sont
jamais rendus plus fins qu'un pixel : de loin, le garde-corps garde ses grandes lignes. Les
barreaux, eux, comptent pour la part du pixel qu'ils couvrent ; de loin, une trame (`dither`)
en fait un voile au lieu de les laisser disparaître ou se boucher.

### 11. Côté matériaux

Trois matériaux de plus : `railing` (le shader), `aluminium` (un métal uni, pour les lisses)
et `appliance` (le blanc cassé des climatiseurs). Le garde-corps prend la teinte des
menuiseries : `"metal_color": frame_color`.

## Ce qu'il faut retenir

1. Regarder comment l'objet réel est fait avant de le modeler : ici, un balcon est un creux.
2. Une pièce nouvelle oblige parfois à refaire une pièce ancienne (le volume arrière).
3. Un ouvrage fin et répété se dessine sur un rectangle, par une distance signée.
4. `min()` réunit deux formes ; `fract()` en répète une.
5. `ALPHA` et un seuil découpent sans transparence, et l'ombre suit la découpe.

## À essayer

- `railing_style` : « Muret plein », puis « Panneaux translucides ».
- `balcony_depth` à 1,8, puis à 0 : plus de balcon, de simples fenêtres.
- `ac_units` à faux.
- `office_floors` à 0 : des balcons à tous les étages.
- Dans le shader : `bar_spacing` à 0,2 ; `bar_width` à 0,03.
- Dans le shader, écrire `ALBEDO = vec3(d * 20.0);` à la fin et retirer la ligne `ALPHA` : on
  voit la distance.
{TWIN}
## Étape suivante

008 : des pièces de métal plié. Un auvent, une couvertine sur l'acrotère, des appuis de
fenêtre, et les descentes d'eau de pluie.
