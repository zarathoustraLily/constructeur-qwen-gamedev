# Tokyo · étape 006 · Niveaux : commerce et étages

**Piste : Building.** Jusqu'ici la façade était une grille : six niveaux identiques. Un petit
immeuble de Tokyo empile des usages : un rez-de-chaussée haut et vitré, quelques étages de
bureaux aux fenêtres en bandeau, des logements au-dessus, et sur un côté la cage d'escalier,
avec ses petites fenêtres dépolies. En haut, un muret borde le toit plat : l'acrotère.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Dans l'inspecteur de l'immeuble, le
groupe **Niveaux** a changé, et un groupe **Façade** est apparu. Appuyer sur N : les étages
ne s'allument plus tous de la même façon.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Le script de l'immeuble est le fichier à
lire ; le shader de fenêtre gagne des pièces. Chercher « NOUVEAU » dans les deux.

## Ce qu'on a fait, dans l'ordre

### 1. De nouvelles variables : décrire, pas dessiner

Les variables `window_width`, `window_height` et `sill_height` ont disparu. À leur place,
des variables qui décrivent l'immeuble comme le ferait quelqu'un qui le regarde :

| Variable | Ce qu'elle dit |
|---|---|
| `ground_height` | hauteur du rez-de-chaussée |
| `floor_count`, `floor_height` | nombre d'étages au-dessus, et leur hauteur |
| `office_floors` | combien de ces étages sont des bureaux, en partant du premier |
| `core_side` | de quel côté est la travée d'escalier : aucune, à gauche, à droite |
| `parapet_height` | hauteur de l'acrotère |
| `office_window_height` | hauteur des fenêtres de bureau |

`office_floors` suffit à décrire trois immeubles : à 0, que des logements ; à 2, un immeuble
mixte ; à 5, que des bureaux. Une bonne variable est une phrase courte sur l'objet.

### 2. Une donnée intermédiaire : la classe `Level`

Entre les variables et la géométrie, on glisse une description : la liste des niveaux.

```gdscript
class Level:
	var height: float = 3.0
	## Ce qu'il y a derrière ses fenêtres : KIND_OFFICE ou KIND_DWELLING.
	var kind: int = 0
	## Largeur et hauteur de la baie.
	var opening: Vector2 = Vector2(1.6, 1.5)
	## Hauteur de l'allège sous la baie.
	var sill: float = 0.85
```

Une classe déclarée à l'intérieur d'un script (`class Level:`) appartient à ce script : elle
ne s'ajoute pas à la liste des classes du projet. Celle-ci ne fait rien : elle porte quatre
valeurs. Les étapes suivantes lui en ajouteront.

### 3. Traduire les variables en niveaux : `_make_levels()`

Cette fonction est la seule qui connaisse les règles de composition. Elle remplit un tableau
de `Level`, du rez-de-chaussée au dernier étage :

```gdscript
		if index < office_floors:
			# Bureaux : des fenêtres larges au-dessus d'une allège, qui forment un bandeau.
			level.kind = KIND_OFFICE
			level.sill = 0.85
			level.opening = Vector2(bay_width - 0.4, office_window_height)
		else:
			# Logements : des fenêtres plus étroites.
			level.kind = KIND_DWELLING
			level.sill = 0.9
			level.opening = Vector2(bay_width - 0.7, 1.2)
```

La largeur des baies se déduit de la travée : `bay_width - 0.4` laisse 20 cm de mur de chaque
côté. Élargir la travée élargit le bandeau, sans autre réglage.

### 4. Monter un niveau : `_build_level()` change de signature

```gdscript
func _build_level(level: Level, index: int, base_y: float) -> float:
```

Elle reçoit un `Level` au lieu d'un numéro, la hauteur où le poser, et renvoie la hauteur de
son plancher haut. `rebuild()` empile :

```gdscript
	var levels: Array[Level] = _make_levels()
	var base_y: float = 0.0
	for index: int in range(levels.size()):
		base_y = _build_level(levels[index], index, base_y)
	_build_parapet(base_y)
```

À l'intérieur, les quatre boîtes autour de chaque baie sont les mêmes qu'à l'étape 001.
Seule nouveauté : la travée d'escalier, qui a sa propre baie, petite et haute.

```gdscript
		var is_core: bool = bay == core and index > 0
		var size: Vector2 = CORE_OPENING if is_core else level.opening
		var sill: float = CORE_SILL if is_core else level.sill
```

`_core_bay()` traduit `core_side` en numéro de travée, ou -1 s'il n'y en a pas. Un immeuble
d'une seule travée n'en a jamais.

### 5. Une donnée par fenêtre

Le shader de fenêtre doit maintenant savoir ce qu'il y a derrière chaque vitre : un bureau,
un logement, un escalier. Et la hauteur de l'allège n'est plus la même partout. Ce sont des
données propres à chaque rectangle, pas au matériau. `panel()` a un argument pour cela :

```gdscript
		var kind: int = KIND_CORE if is_core else level.kind
		_panel(size, Vector3(x, bottom + 0.5 * size.y, glass_z), _materials.window, Color(float(kind), sill, 0.0, 0.0))
```

Ce `Color` n'est pas une couleur : ce sont quatre nombres libres, attachés à l'instance. Le
shader les reçoit dans `INSTANCE_CUSTOM` :

```glsl
	v_custom = INSTANCE_CUSTOM;
```

```glsl
	int kind = int(v_custom.x + 0.5);
	float sill = v_custom.y;
```

Un seul matériau sert donc à toutes les fenêtres de l'immeuble, et un seul appel de dessin
les trace toutes. L'uniforme `sill_height` de l'étape 005 a disparu du shader.

`_panel()` est une petite fonction du script, qui appelle `_mesh.panel()` face à la rue. Elle
paraît inutile ; elle prendra son sens à l'étape 009, quand des étages entiers reculeront.

### 6. Dans le shader : une fonction par sorte de pièce

L'étape 005 avait séparé « quelle paroi » de « de quelle couleur ». Il suffit d'ajouter une
fonction, `dwelling_surface()`, et de choisir :

```glsl
	vec3 albedo;
	if (kind == KIND_DWELLING) {
		albedo = dwelling_surface(face, m, extent, soft, r4, r6, fixture);
	} else {
		albedo = office_surface(face, m, extent, soft, r4, fixture);
	}
```

Un logement : des murs beige sable, un plancher, un plafonnier rond, et au fond un placard à
portes coulissantes, deux panneaux de papier dans un cadre sombre.

La lumière dépend aussi de la pièce :

```glsl
	if (kind == KIND_DWELLING) {
		lit_share = mix(home_lit_day, home_lit_night, night);
		// Deux logements sur trois ont une lumière chaude, les autres un blanc froid.
		light_tint = r9 < 0.66 ? pc_color_in(lamp_color) : light_tint;
	} else if (kind == KIND_CORE) {
		// Un escalier reste allumé toute la nuit.
		lit_share = mix(0.3, 1.0, night);
	}
```

Les bureaux se vident le soir, les logements s'allument : la nuit, on lit l'usage de chaque
étage sur la façade.

Deux autres branches : les logements ont des voilages et des rideaux à la place du store, et
la cage d'escalier a un verre dépoli, qui laisse passer la lumière mais pas les formes. Pour
elle, le shader ne garde qu'une lueur.

### 7. L'acrotère

```gdscript
func _build_parapet(base_y: float) -> void:
	var width: float = get_facade_width()
	_wall(Vector3(width, parapet_height, PARAPET_DEPTH), Vector3(0.0, base_y + 0.5 * parapet_height, -0.5 * PARAPET_DEPTH), _materials.facade)
```

Un toit plat a toujours un muret autour de lui. Pour l'instant, c'est un morceau de mur de
plus, et le volume arrière monte jusqu'en haut : le toit est un bloc plein. L'étape 009 le
creusera.

## Ce qu'il faut retenir

1. Les variables décrivent l'objet ; une fonction les traduit en une liste de pièces ; une
   autre monte ces pièces. Trois étages, toujours les mêmes.
2. Une classe interne peut ne servir qu'à porter des valeurs.
3. `INSTANCE_CUSTOM` donne quatre nombres à chaque rectangle : un seul matériau, des
   fenêtres différentes.
4. Dans un shader, une fonction par variante, avec les mêmes arguments.

## À essayer

- `office_floors` à 0, puis à 5.
- `core_side` : « À droite », puis « Aucune ».
- `bay_count` à 1 : la travée d'escalier disparaît toute seule.
- `office_window_height` à 2 : presque un mur de verre.
- N : compter les bureaux et les logements allumés.
{TWIN}
## Étape suivante

007 : les logements reçoivent des balcons en creux, avec leurs garde-corps et leurs
climatiseurs. Un nouveau shader dessine les barreaux.
