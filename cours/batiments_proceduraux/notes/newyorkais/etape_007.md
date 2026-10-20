# New York · étape 007 · Mur-rideau : tours de verre, de 1961 à aujourd'hui

**Piste : Building + Shader.** En 1961, New York change de règlement. Plus d'enveloppe en
gradins : une tour peut monter droit, à condition de reculer des rues, de ne couvrir qu'une part
du terrain et de ne pas dépasser une surface de planchers. La tour de verre, posée sur sa place,
en est la forme type. Ce règlement est toujours en vigueur : la tour tout en verre d'aujourd'hui
lui obéit aussi. Trois familles de tours, un seul script.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. La visite montre trois tours côte à côte,
sur trois terrains de même taille : la tour de brique de 1916, la tour de verre de 1961, la tour
tout en verre d'aujourd'hui. Appuyer sur **N** : les bureaux s'allument derrière le verre comme
derrière les fenêtres.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Trois scènes de tour, un seul script : les deux
tours de verre ne diffèrent de la tour de brique que par leurs variables. Lire le script de la
tour (chercher « NOUVEAU »), puis le nouveau shader `…_mur_rideau.gdshader`, puis le fichier
partagé `…_bureau.gdshaderinc`.

## Ce qu'on a fait, dans l'ordre

### 1. Trois familles, une variable

```gdscript
@export_enum("Brique (1916)", "Verre et allèges (1961)", "Tout en verre (aujourd'hui)") var family: int = 0
```

`family` choisit la famille. Elle aiguille deux fonctions : celle qui fabrique les gradins, et
celle qui les monte.

```gdscript
	if family == FAMILY_BRICK:
		return _make_setback_tiers()
	return _make_glass_tiers()
```

La liste des gradins de l'étape 006 sert toujours : une tour de verre n'est qu'une autre façon de
la remplir, et de la monter.

### 2. Le règlement de 1961, dans `5_data`

Le règlement de 1961 ne dessine plus d'enveloppe pour la tour. Il fixe des distances, une part
du terrain et une surface. Le cours suit le texte en vigueur aujourd'hui, pour les districts
commerciaux les plus denses (C5 et C6) :

```gdscript
const WIDE_STREET: float = 75.0 * FOOT
const FRONT_WALL_MAX: float = 85.0 * FOOT
const FRONT_WALL_FLOORS: int = 6
const TOWER_SETBACK_NARROW: float = 15.0 * FOOT
const TOWER_SETBACK_WIDE: float = 10.0 * FOOT
const FLOOR_AREA_RATIO: float = 15.0
```

- une rue est **large** à partir de 75 pieds : une avenue de 100 pieds l'est, une rue
  transversale de 60 pieds ne l'est pas ;
- un socle bâti à l'alignement ne dépasse pas 85 pieds ni six étages ;
- la tour se tient à 15 pieds au moins d'une rue étroite, 10 pieds d'une rue large ;
- la tour couvre au plus 40 % d'un grand terrain ; un peu plus d'un petit, selon une table que
  la palette traduit en une fonction, `tower_share_1961()` ;
- la surface de tous les planchers vaut au plus **quinze fois** celle du terrain : c'est le
  coefficient d'occupation, en anglais « floor area ratio ».

### 3. La hauteur sort d'une division

```gdscript
	var area_left: float = Palette.FLOOR_AREA_RATIO * lot.get_area() - float(podium) * lot.get_area()
	var tower_floors: int = floori(area_left / tower.get_area())
```

Le règlement ne fixe pas la hauteur de la tour : il fixe la surface de ses planchers. Le nombre
d'étages en sort par une division. `floor_count` ne sert donc pas aux tours de verre. Sur le même
terrain de 45 m sur 61 m :

| Tour | Emprise | Part du terrain | Étages | Hauteur |
|---|---|---|---|---|
| Verre, 1961 | 31,9 m × 31,9 m | 37 % | 40 | 148 m |
| Tout en verre | 27,4 m × 27,4 m | 27 % | 55 | 232 m |

Une tour plus fine monte plus haut : c'est la même surface de bureaux, empilée autrement. La tour
d'aujourd'hui a aussi des étages plus hauts (4,20 m) : du verre du sol au plafond.

Un socle est possible (`podium_floors`) : il occupe tout le terrain, sous ses 85 pieds, et la
tour monte au-dessus. Par défaut, il n'y en a pas : la tour se dresse seule.

### 4. L'emprise de la tour de verre

```gdscript
	var free: Rect2 = lot
	for side: int in range(4):
		free = _shrink(free, side, _tower_setback(_street(side)))
	var allowed: float = minf(glass_tower_share, Palette.tower_share_1961(lot.get_area())) * lot.get_area()
```

D'abord le terrain, moins ce que la tour doit à chaque rue. Puis, dans ce qui reste, la plus
grande emprise permise. Ses côtés font un nombre entier de **modules** de façade (`module_width`,
cinq pieds, 1,52 m) : l'écart entre deux meneaux. Comme pour la tour de 1916, on préfère les
emprises presque carrées.

### 5. La place

Une tour sans socle se dresse sur une place, qui occupe le reste du terrain : un dallage de
granit. Le dallage est encore le shader de la brique, couché, avec d'autres nombres : des dalles
de 0,90 m sur 0,60 m, sans boutisses, sans coulures. Le règlement de 1961 accordait des étages
en plus contre une place ouverte au public : c'est d'elle que vient la tour posée sur sa place.
Le cours ne compte pas ce bonus : ses tours restent à quinze fois leur terrain.

### 6. Monter une tour de verre : un rectangle par façade

```gdscript
		_mesh.panel(Vector2(width, height), frame * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.5 * (tier.base_y + top), 0.0)),
				_materials.curtain, Color(float(tier.first_floor), float(_first_module(rect, side)), float(side), 0.0))
```

La tour de brique posait des centaines de boîtes et une fenêtre par baie. La tour de verre n'a
plus de mur porteur en façade : sa façade est une peau accrochée au bord des planchers, faite
d'un seul motif répété. On pose donc **un seul rectangle par façade**, de toute sa largeur et de
toute sa hauteur. Le shader du mur-rideau dessine le reste. Derrière, un noyau sombre porte les
ombres et le toit.

La donnée de l'instance donne au shader le premier étage du rectangle, sa première colonne et sa
façade : les nombres de la clé de tirage des pièces, comme pour les fenêtres de brique.

Résultat : une tour de verre de 40 étages fait 92 triangles.

### 7. Le shader du mur-rideau

Il part des UV, comme la fenêtre. `floor()` y fait deux fois son travail : les modules en
largeur, les étages en hauteur.

```glsl
	float modules = max(1.0, floor(w / module_width + 0.5));
	float unit = w / modules;
	float column = min(floor(q.x / unit), modules - 1.0);
	float xl = q.x - column * unit;
	float to_mullion = min(xl, unit - xl);
```

Un nombre entier de modules remplit la façade : le module est retouché pour tomber juste.
`to_mullion` est la distance au meneau le plus proche.

En hauteur, le rez-de-chaussée est plus haut que les autres étages : `level` est le numéro de
l'étage, `base` la hauteur de son plancher sur le rectangle. Dans chaque étage, le **verre de
vision** va de l'allège à la bande opaque du haut. Une seule distance décide de tout :

```glsl
	float inside = min(min(yl - vision_low, vision_high - yl), to_mullion - 0.5 * mullion_width);
	float glass_cover = pc_step(0.0, inside, footprint);
```

Positive dans le verre de vision, négative sur le métal ou la bande opaque. Puis les meneaux et
les deux traverses qui bordent la bande, en métal ; la bande elle-même, en verre émaillé.

### 8. 1961 et aujourd'hui : les mêmes lignes, d'autres nombres

| Réglage | Verre, 1961 | Tout en verre |
|---|---|---|
| `sill_height` | 0,80 m d'allège opaque | 0 : du verre du sol au plafond |
| `head_band` | 0,45 m | 0,60 m : la dalle et le faux plafond |
| `glass_spandrels` | non : un émail mat | oui : du verre sombre, aussi brillant que le reste |
| `mullion_width` | 7 cm | 5 cm |
| `reflectivity` | 0,85 | 0,95 |

Le script des matériaux choisit ces nombres d'après la famille. Le shader ne sait pas quelle
tour il dessine : il dessine des bandes, des meneaux et du verre, aux cotes qu'on lui donne.

### 9. Les mêmes bureaux, derrière le verre : `…_bureau.gdshaderinc`

Derrière le verre, il y a des bureaux, les mêmes que derrière les fenêtres de brique. Plutôt que
de recopier la pièce de l'étape 005 dans le second shader, on l'a sortie du shader de la fenêtre,
telle quelle, rangée en fonctions, dans un fichier `.gdshaderinc` que les deux shaders incluent :

```glsl
#include "res://6_assets/Shader/Procedural/DECORS/Building/building_proceduraux_newyorkais_etape_007_bureau.gdshaderinc"
```

Il fournit `room_view()` : le rayon dans la boîte, les cloisons basses, la lumière, le store. Le
shader qui l'appelle lui donne la vitre, la boîte de la pièce, son tirage et son étage :

```glsl
	vec3 interior = room_view(pane_q, pane, VIEW, v_axis_x, v_axis_y, room, depth, lobby, r0, level, footprint, near_light);
```

Ce fichier vit à côté des shaders de la tour, et non avec `procedural_commun`, parce qu'il ne
sert qu'à elle. Les pièces d'une tour de verre sont plus profondes (12 m au plus) : un plateau de
bureaux moderne s'éclaire à la lampe plus qu'à la fenêtre.

### 10. Trois scènes, un script

Les deux tours de verre sont deux scènes de plus, `…_verre.tscn` et `…_verre_integral.tscn`.
Elles portent le même script que la tour de brique : seules leurs variables diffèrent (la
famille, les rues, les teintes). Une scène, c'est un script et des valeurs.

### 11. Le test vérifie le nouveau règlement

`get_zoning_margin()` sait maintenant mesurer les deux règlements : sous l'enveloppe pour une
tour de brique ; pour une tour de verre, le retrait gardé en plus des 15 ou 10 pieds, et le socle
sous ses 85 pieds. `get_floor_area_ratio()` compare la surface des planchers à celle du terrain.
Le test refuse une tour qui dépasse quinze fois son terrain.

## Ce qu'il faut retenir

1. Un même script peut porter plusieurs familles : une variable aiguille la règle et la
   construction, la description intermédiaire (les gradins) reste la même.
2. Un règlement de surface donne la hauteur par une division : une tour plus fine monte plus
   haut.
3. Une façade répétitive se dessine sur un seul rectangle : 92 triangles pour une tour de
   40 étages.
4. Du code de shader partagé par deux shaders va dans un `.gdshaderinc`, rangé en fonctions.

## À essayer

- Dans la scène `…_verre.tscn`, `glass_tower_share` à 0,2 : la tour s'affine et monte.
- `podium_floors` à 6 : un socle de six étages, et la tour au-dessus.
- `family` de la tour de brique à « Tout en verre » : le même terrain, une autre époque.
- `module_width` à 3 : de grands carreaux, des meneaux plus rares.
- N : comparer les bureaux allumés derrière les fenêtres et derrière le verre.
{TWIN}
## Étape suivante

008 : les profils. Le chaperon de pierre qui coiffe chaque gradin, un bandeau qui souligne le
socle, les ailettes de métal du mur-rideau, la marquise de l'entrée.

## Sources

- Ville de New York, *Zoning Resolution*, texte en vigueur : section 12-10 (rue large : 75 pieds
  ou plus) ; section 33-432 (mur de façade de 85 pieds ou six étages au plus) ; section 33-451
  (tour sur 40 % du terrain au plus, à 15 pieds d'une rue étroite et 10 pieds d'une rue large) ;
  section 33-454 (la part des petits terrains : 50 % jusqu'à 10 500 pieds carrés, puis un point
  de moins par tranche de 1 000 pieds carrés, 41 % jusqu'à 19 999) ; section 33-122 (coefficient
  de 15 dans les districts C5-3, C5-5, C6-6, C6-7 et C6-9). La définition de la section 12-10 a
  été lue dans sa reproduction par la City University of New York (City Tech, OpenLab).
- The Skyscraper Museum, « The 1961 Zoning Law » : le principe du coefficient d'occupation, et
  les surfaces en plus accordées contre une place.
- Museum of the City of New York, *The Greatest Grid*, « Plazas » : la place de la tour de verre
  comme contrepartie du règlement.
- Le module de cinq pieds, les cotes des bandes et des meneaux, et la profondeur des plateaux de
  bureaux sont des choix du cours, plausibles, non relevés sur une tour réelle.
