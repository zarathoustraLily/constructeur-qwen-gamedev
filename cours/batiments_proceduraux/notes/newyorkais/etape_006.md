# New York · étape 006 · Gradins : le règlement de 1916

**Piste : Building.** Jusqu'ici la tour était un prisme de 30 étages identiques. Une tour de
Manhattan des années 1920 a une autre silhouette : elle monte droit sur la rue, puis recule par
gradins, et finit en une tour plus mince qui monte sans limite. Cette forme n'est pas un choix
d'architecte : c'est le règlement de zonage de 1916 qui la dessine. On l'écrit en code, et la
tour en sort toute seule.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. La tour a changé de forme : un socle de
pierre, trois gradins de brique, une tour. Dans l'inspecteur, deux groupes nouveaux :
**Terrain** et **Règlement de 1916**. Changer `height_district` ou `street_front` : les gradins
se déplacent.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Lire d'abord la palette de `5_data`, qui porte
les nombres du règlement, puis le script de la tour : la fonction `_make_setback_tiers()` est le
cœur de l'étape.

## Ce qu'on a fait, dans l'ordre

### 1. Le règlement de 1916, en une phrase

Le règlement de zonage de New York de 1916 a voulu garder de la lumière et de l'air dans les
rues, au pied des tours. Il fixe, pour chaque rue, une **enveloppe** :

- la façade sur rue peut monter droit jusqu'à un multiple de la largeur de la rue : une fois,
  une fois et quart, une fois et demie, deux fois ou deux fois et demie, selon le district ;
- au-delà, la tour doit rester sous un plan incliné qui part de l'axe de la rue. Dans un
  district « deux fois », un pied de recul pour quatre pieds de hauteur ;
- une partie de la tour, au plus le quart du terrain, peut monter **sans limite de hauteur**.

D'où la silhouette en gâteau de mariage : chaque gradin recule pour rester sous le plan, jusqu'à
ce que la tour, assez mince, s'en affranchisse.

### 2. Les nombres du règlement sont des données : `5_data`

Les règlements de New York comptent en pieds. Le cours compte en mètres. La palette écrit chaque
nombre dans son unité d'origine, puis le convertit, et dit d'où il vient :

```gdscript
const FOOT: float = 0.3048
const STREET_WIDTH: float = 60.0 * FOOT
const AVENUE_WIDTH: float = 100.0 * FOOT
const BLOCK_DEPTH: float = 200.0 * FOOT
const HEIGHT_MULTIPLES: Array[float] = [1.0, 1.25, 1.5, 2.0, 2.5]
const TOWER_SHARE_1916: float = 0.25
```

La trame de Manhattan d'abord : des rues transversales de 60 pieds, des avenues de 100, des îlots
de 200 pieds d'une rue à l'autre. Puis le règlement : les cinq multiples des districts, et le
quart du terrain. Ce ne sont pas des choix de code : ils vivent dans `5_data`, et le script de la
tour les lit sans les inventer.

### 3. Un terrain et ses rues

La tour ne se décrit plus par ses travées, mais par son terrain, et par ce qui l'entoure :

| Variable | Défaut | Ce qu'elle dit |
|---|---|---|
| `lot_width`, `lot_depth` | 45 m sur 61 m | un terrain qui traverse l'îlot, d'une rue à l'autre (200 pieds) |
| `street_front`, `street_back` | 18,29 m | une rue transversale de 60 pieds devant et derrière |
| `street_right` | 30,48 m | une avenue de 100 pieds à droite : c'est un terrain d'angle |
| `street_left` | 0 | à gauche, un voisin : un mur mitoyen, sans fenêtre |
| `floor_count` | 40 | étages au-dessus du rez-de-chaussée |
| `ground_height` | 5,5 m | un rez-de-chaussée haut |
| `stone_floors` | 3 | le socle de pierre, rez-de-chaussée compris |
| `height_district` | « 2 fois » | le district de hauteur |
| `setback_bays` | 3 | la profondeur d'un retrait, en travées |
| `tower_share` | 0,25 | la part du terrain que la tour couvre, au plus le quart |

Le terrain est un `Rect2` dans le plan : centré sur `x = 0`, de l'alignement de devant (`y = 0`)
vers l'arrière. Une rue de largeur 0 veut dire : pas de rue, un voisin.

### 4. L'enveloppe : un plan incliné

```gdscript
func _envelope_height(street: float, distance: float) -> float:
	var multiple: float = Palette.HEIGHT_MULTIPLES[height_district]
	return 2.0 * multiple * (0.5 * street + distance)
```

Le plan part de l'axe de la rue, au sol. À l'alignement, une demi-rue plus loin, il doit passer
à `multiple` fois la largeur de la rue : sa pente est donc `2 × multiple`. Pour une rue de
60 pieds dans un district « deux fois », la façade monte droit jusqu'à 120 pieds, 36,6 m, puis
chaque mètre de recul donne quatre mètres de plus. C'est la formule qu'on retrouve dans les deux
exemples des sources (voir en fin de note).

### 5. Une description intermédiaire : la classe `Tier`

Entre les variables et la géométrie, on glisse une description : la liste des gradins.

```gdscript
class Tier:
	var rect: Rect2 = Rect2()
	var first_floor: int = 0
	var floor_count: int = 0
	var base_y: float = 0.0
	var top_y: float = 0.0
	var tower: bool = false
```

Un gradin est un prisme droit : un rectangle du plan, un premier étage, un nombre d'étages. Le
drapeau `tower` dit s'il appartient à la tour, qui a le droit de percer l'enveloppe.
`_make_tiers()` fabrique la liste, du bas vers le haut ; `_build_tier()` monte chaque gradin.
Ce sont deux métiers : la règle, puis la construction.

### 6. Appliquer le règlement, étage par étage : `_make_setback_tiers()`

La fonction monte la tour un étage à la fois. Pour chaque étage :

1. chaque rue demande un retrait, pour que le haut de l'étage, parapet compris, reste sous son
   enveloppe. On renverse la formule de l'enveloppe : à quelle distance le plan atteint-il cette
   hauteur ?

```gdscript
				var needed: float = top / (2.0 * multiple) - 0.5 * street
				if needed <= 0.0:
					continue
				plate = _shrink(plate, side, ceilf(needed / step - 0.0001) * step)
```

2. le retrait est arrondi au retrait entier suivant : `setback_bays` travées. L'enveloppe
   permettrait un escalier d'étage en étage ; l'architecte regroupe les retraits en quelques
   gradins francs ;
3. si l'emprise de l'étage ne contient plus celle de la tour, l'étage appartient à la tour : à
   partir de là, elle monte droit, sans limite ;

```gdscript
			in_tower = tower.has_area() and not plate.grow(0.001).encloses(tower)
		if in_tower:
			plate = tower
```

4. un étage de même emprise que celui du dessous prolonge son gradin ; sinon, il en commence un
   nouveau.

```gdscript
		if not tiers.is_empty() and tiers.back().rect.is_equal_approx(plate):
			var current: Tier = tiers.back()
			current.floor_count += 1
			current.top_y = _floor_y(index + 1)
		else:
			tiers.append(_tier(plate, index, 1, in_tower))
```

Sur le terrain par défaut, cela donne quatre gradins : le socle et huit étages sur tout le
terrain, jusqu'à 34,8 m ; six étages en retrait de 6 m sur les deux rues ; sept étages en retrait
de 12 m sur les rues et de 6 m sur l'avenue ; puis la tour, 19 étages de 25 m sur 25 m, jusqu'à
152 m. Personne n'a dessiné ces gradins : ils sortent du règlement.

### 7. L'emprise de la tour

La tour peut couvrir au plus le quart du terrain. `_tower_rect()` cherche la plus grande emprise
permise, centrée sur le terrain, qui recule d'un nombre entier de travées de chaque côté, pour
que ses fenêtres tombent dans l'alignement de celles du dessous. Entre deux emprises de même
surface, elle préfère la plus carrée :

```gdscript
			var score: float = size.x * size.y * minf(size.x, size.y) / maxf(size.x, size.y)
```

Un carré garde toute sa surface ; un rectangle deux fois plus long que large n'en garde que la
moitié. Ici : 25 m sur 25 m, 22,8 % du terrain.

### 8. Monter un gradin : `_build_tier()`

Les façades de l'étape 001 servent toujours, gradin par gradin. Chaque gradin monte ses quatre
façades, ses piliers d'angle, son noyau et son toit, et quelques règles s'ajoutent :

- **les repères des façades** viennent du rectangle du gradin : `_face_frame(rect, side)` pose
  l'origine au milieu du pied de la façade, l'axe `x` le long d'elle, l'axe `z` vers le dehors ;
- **le mur mitoyen** : un côté sans rue, sur la limite du terrain, est contre un voisin. C'est un
  mur plein, sans fenêtre ;
- **le socle de pierre** : tout ce qui finit sous le haut du socle (`stone_floors` niveaux) est en
  pierre, le reste en brique. La pierre est le shader de la brique, avec d'autres nombres : des
  blocs de 1,50 m sur 0,61 m, pas de boutisses, un joint plus fin ;
- **le parapet** : un mur de 1,10 m borde le toit de chaque gradin. Il compte dans la hauteur :
  c'est lui qui doit rester sous l'enveloppe ;
- **ce que couvre le gradin du dessus** : là où le gradin du dessus monte dans le même plan,
  sans retrait, le mur continue. Pas de parapet à cet endroit : `_covered_span()` le mesure, et
  `_wall_run()` arrête le mur au toit. Sans cela, deux murs dans le même plan se chevaucheraient
  sur la hauteur du parapet, et la carte graphique ne saurait pas lequel montrer.

Le rez-de-chaussée a ses propres baies, plus hautes, et derrière elles un hall : murs de marbre,
portes d'ascenseur de bronze, plafond à caissons et lustres. Il reste allumé jour et nuit.

### 9. Une clé de tirage exacte : la donnée de l'instance

À l'étape 005, une fenêtre tirait ses dés d'après sa position. Avec des gradins, ce n'est plus
assez : une pièce s'étend sur plusieurs fenêtres, et il faut que toutes tirent la même. Le script
donne donc à chaque fenêtre quatre nombres, attachés à son instance :

```gdscript
			_mesh.panel(size, frame * Transform3D(Basis.IDENTITY, center), _materials.window,
					Color(kind, float(index), float(first_column + bay), float(side)))
```

Ce `Color` n'est pas une couleur : ce sont quatre nombres libres. Ce qu'il y a derrière (un bureau
ou le hall), l'étage, la colonne, la façade. Les colonnes sont comptées depuis le bout de la
façade du **terrain**, pas du gradin : une fenêtre garde son numéro de colonne d'un gradin à
l'autre. Le shader les reçoit dans `INSTANCE_CUSTOM`, et en fait les pièces :

```glsl
	float span = 1.0 + floor(pc_hash2(vec2(v_key.x, v_key.z * 31.0 + 5.0)) * 3.0);
	float room_id = floor(v_key.y / span);
	float place = v_key.y - room_id * span;
	float r0 = pc_hash3(vec3(v_key.x, room_id, v_key.z + 17.0));
```

Sur un même étage d'une même façade, toutes les pièces ont la même largeur, `span` travées.
`room_id` est le numéro de la pièce le long de l'étage, `place` celui de la fenêtre dans sa pièce.
Toutes les fenêtres d'une pièce ont le même `r0` : la même profondeur, la même lumière, le même
store. La nuit, une pièce s'allume d'un bloc, sur deux ou trois fenêtres.

### 10. Vérifier le règlement : le test

Le script de la tour sait mesurer sa propre conformité :

```gdscript
			var envelope: float = _envelope_height(street, _setback_from(lot, tier.rect, side))
			margin = minf(margin, envelope - (tier.top_y + _parapet_top()))
```

`get_zoning_margin()` renvoie la plus petite distance entre le haut d'un gradin, parapet compris,
et l'enveloppe d'une rue ; `get_tower_coverage()`, la part du terrain couverte par la tour, et la
part permise. Le test de l'étape refuse une tour qui percerait l'enveloppe ou couvrirait plus que
le quart du terrain. Sur la tour par défaut : 70 cm de marge, 22,8 % du terrain.

## Ce qu'il faut retenir

1. Une règle d'urbanisme s'écrit en code : la forme de la tour en sort, personne ne la dessine.
2. Les nombres du règlement sont des données : dans `5_data`, dans leur unité d'origine, avec leur
   source.
3. Une description intermédiaire (la liste des gradins) sépare la règle de la construction.
4. Une clé de tirage faite de nombres entiers (étage, colonne, façade) est exacte et partageable :
   plusieurs fenêtres peuvent tirer la même pièce.
5. Un script qui applique une règle doit savoir la vérifier.

## À essayer

- `height_district` de « 1 fois » à « 2½ fois » : les gradins montent.
- `street_front` à 30,48 : une avenue devant, le premier retrait monte.
- `street_right` à 0 : le terrain n'est plus d'angle, le côté droit devient mitoyen.
- `setback_bays` à 1 : des retraits d'une travée, un escalier presque continu.
- `tower_share` à 0,10 : une tour plus mince, qui commence plus haut.
- `lot_width` à 20 : un petit terrain, et une tour qui n'a presque plus de place.
{TWIN}
## Étape suivante

007 : l'autre règlement, celui de 1961. Plus d'enveloppe : une tour de verre, sur une place.
Et la tour tout en verre d'aujourd'hui, avec les mêmes règles.

## Sources

- Museum of the City of New York, *The Greatest Grid*, « The Commissioners' Plan, 1811 » : rues
  transversales de 60 pieds, avenues de 100 pieds, îlots de 200 pieds du nord au sud.
- Museum of the City of New York, *The Greatest Grid*, « The Setback Principle of the 1916 Zoning
  Law » : les variantes de la formule selon la largeur de la rue, et la tour sans limite de
  hauteur sur 25 % du terrain.
- Carol Willis, The Skyscraper Museum, « How the 1916 Zoning Law Shaped Manhattan's Central
  Business Districts », 2016 : les districts une fois, une fois et quart, une fois et demie, deux
  fois, deux fois et demie ; le plan incliné tracé depuis l'axe de la rue ; dans un district
  « une fois et demie », un pied de recul pour trois pieds de hauteur, dans un district « deux
  fois », un pour quatre. La pente `2 × multiple` du cours est déduite de ces deux exemples.
- Les cotes du terrain par défaut, celles des étages et du parapet, et le regroupement des
  retraits par travées sont des choix du cours, plausibles, non relevés sur une tour réelle.
