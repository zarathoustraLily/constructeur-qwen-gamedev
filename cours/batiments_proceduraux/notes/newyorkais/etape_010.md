# New York · étape 010 · Rez-de-chaussée : hall, porte tambour, boutiques

**Piste : Building + Shader.** Le rez-de-chaussée est la partie de la tour qu'on voit de plus
près : celle qu'on touche. La tour de brique reçoit une entrée encadrée de bronze, avec ses
portes tambour, et des boutiques tout autour, chacune avec sa vitrine, sa porte et son enseigne.
Les tours de verre gardent leur hall vitré, avec leurs portes tambour, et leur place reçoit des
jardinières. Le numéro de la tour s'affiche sur sa marquise.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Descendre au niveau de la rue (touche A) et
longer la tour de brique : une épicerie, un café, un magasin, chacun avec son nom. Appuyer sur
**N** : les boutiques ouvertes s'éclairent, les cafés d'une lumière chaude.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Deux fichiers nouveaux : le script du
rez-de-chaussée `…_rez_de_chaussee.gd`, et le shader du bronze. Les listes de noms et de teintes
sont dans la palette de `5_data`.

## Ce qu'on a fait, dans l'ordre

### 1. Le rez-de-chaussée a son propre script

Comme le couronnement à l'étape 009 : un script à part, dont toutes les fonctions sont `static`.
Le script de la tour lui confie le bas de chaque façade de brique ; la façade des étages commence
au-dessus de lui.

```gdscript
	var ground: bool = tier.first_floor == 0
	var bottom: float = ground_height if ground else tier.base_y
	var first_floor: int = 1 if ground else tier.first_floor
```

```gdscript
		GroundBuilder.masonry_face(_mesh, _materials, _random, frame, width, bay_width, pier, WALL_DEPTH, PIER_PROJECTION,
				ground_height, side, first_column, side == 0)
```

`masonry_face()` reçoit tout ce qu'il lui faut, et rien de plus : la façade, ses cotes, sa clé
de tirage, et si elle porte l'entrée.

### 2. Découper la façade

Le rez-de-chaussée d'une façade est découpé en morceaux : au milieu de la façade de devant,
l'entrée de la tour, trois travées ; partout ailleurs, des boutiques de deux ou trois travées.
Entre deux morceaux, un pilastre de pierre ; au-dessus de tous, un linteau de pierre qui porte
les piliers des étages.

```gdscript
			var drawn: int = random.randi_range(2, 3)
			var limit: int = (entrance_first if bay < entrance_first else bays) - bay
			var size: int = mini(drawn, limit)
```

Le dé est lancé à chaque morceau, **même quand la place manque** : s'il ne reste qu'une travée,
on tire quand même, puis on rabote. Ainsi le nombre de tirages ne dépend que de la largeur de la
façade, et les boutiques des autres façades ne changent pas quand celle-ci change. C'est la
discipline des tirages, qu'on reverra à l'étape 011.

### 3. Une boutique

Chaque boutique tire, toujours dans le même ordre et toujours toutes : sa sorte, son nom, la
teinte de son bandeau, le côté de sa porte.

```gdscript
	var shop_type: int = random.randi_range(0, Palette.SHOP_NAMES.size() - 1)
	var names: PackedStringArray = PackedStringArray(Palette.SHOP_NAMES[shop_type])
	var shop_name: String = names[random.randi_range(0, names.size() - 1)]
	var fascia_color: Color = Palette.FASCIA_COLORS[random.randi_range(0, Palette.FASCIA_COLORS.size() - 1)]
	var door_left: bool = random.randf() < 0.5
```

Puis elle se monte : le bandeau d'enseigne peint, son nom en lettres claires, la porte vitrée
d'un côté avec une imposte au-dessus, la vitrine sur tout le reste, posée sur un soubassement de
pierre. Les vitres sont des rectangles instanciés, en retrait de 25 cm derrière le nu de la
façade, avec le shader de la fenêtre.

Les noms et les teintes sont des données : ils vivent dans la palette.

```gdscript
const SHOP_NAMES: Array[Array] = [
	["DELI", "GROCERY", "PHARMACY", "NEWSSTAND", "MARKET"],
	["COFFEE", "DINER", "BAKERY", "BAR & GRILL", "PIZZA"],
	["SHOES", "FLOWERS", "OPTICIAN", "BOOKS", "TAILOR", "JEWELRY"],
]
```

Des noms communs, en anglais, comme sur les enseignes de Manhattan ; aucun n'est celui d'une
boutique réelle. Chaque ligne est une sorte de boutique : une épicerie, un café, un magasin. La
sorte décidera de la pièce que le shader dessine derrière la vitrine.

Un détail d'écriture : ce tableau de tableaux est typé `Array[Array]`. Pendant l'écriture du
cours, un tableau constant `Array[PackedStringArray]` écrit de la même façon a fait planter
Godot 4.7.2 à la lecture ; `Array[Array]` fonctionne.

### 4. Du vrai texte : `Label3D`

Le nom de la boutique n'est pas dessiné par un shader : c'est un `Label3D`, le nœud de Godot qui
écrit du vrai texte dans la scène. L'outil de maillage l'accepte comme un nœud tout fait :

```gdscript
	var label: Label3D = _label(shop_name, Color(0.95, 0.90, 0.78), Vector2(width - 0.4, 0.62 * FASCIA))
	label.transform = frame * Transform3D(Basis.IDENTITY, Vector3(middle, opening_top - 0.5 * FASCIA, 0.145))
	mesh.node(label)
```

La taille du texte se règle par `pixel_size`, la taille d'un pixel de la police dans la scène :
pour qu'un caractère de 64 pixels mesure `height` mètres, `pixel_size` vaut `height / 64`. Le
texte doit tenir dans la hauteur du bandeau, et dans sa largeur s'il est long : une lettre latine
fait à peu près les deux tiers de sa hauteur en largeur, d'où le calcul de `height` dans
`_label()`.

Le numéro de la tour, sur le devant de la marquise, est un autre `Label3D`. À Manhattan, beaucoup
de tours se désignent par leur adresse : un numéro dans la rue ou l'avenue. Il est tiré au sort.

### 5. Un matériau par teinte, à la demande

Quatre teintes de bandeau, mais des dizaines de boutiques. Plutôt que de créer un matériau par
boutique, le script des matériaux en fabrique un par teinte, à la première demande :

```gdscript
func lacquer(color: Color) -> StandardMaterial3D:
	if not _plain_colors.has(color):
		_plain_colors[color] = _plain(color, 0.45, 0.1)
	return _plain_colors[color]
```

Deux boutiques de même teinte partagent le leur. L'outil de maillage range la géométrie par
matériau : quatre matériaux, quatre maillages, quatre appels de dessin, quel que soit le nombre de
boutiques.

### 6. La porte tambour

Quatre vantaux de verre qui tournent autour d'un axe, dans un tambour : la porte tambour laisse
passer les gens sans laisser passer l'air. Dans une tour, l'air chaud monte comme dans une
cheminée ; une porte ordinaire serait aspirée ou repoussée.

Elle est faite de ce qu'on connaît déjà : des cylindres (des cônes à deux rayons égaux) pour le
toit, le socle et l'axe ; des rectangles instanciés pour le verre. Les vantaux sont en croix,
tournés d'un huitième de tour :

```gdscript
		var angle: float = 0.25 * PI + 0.5 * PI * float(index)
		var along: Vector3 = frame.basis * Vector3(cos(angle), 0.0, sin(angle))
		var wing: Basis = Basis(along, up, along.cross(up))
```

Un rectangle instancié n'a qu'une face : chaque vantail en pose deux, dos à dos (un demi-tour de
plus). Les deux parois courbes, sur les côtés, sont des facettes de verre posées sur un arc de
cercle : cinq de chaque côté.

### 7. Derrière la vitrine : trois boutiques de plus dans le shader

Le shader de la fenêtre connaît trois sortes de vitres de plus, que le script écrit dans la donnée
de l'instance : la vitrine (une glace fixe dans un cadre mince), la porte vitrée (un cadre plus
large, une traverse basse, une barre de poussée à hauteur de main), le verre des portes tambour
(sans cadre). Pour une vitre du rez-de-chaussée, la donnée porte la sorte de boutique à la place
de l'étage.

Derrière, la pièce est une boutique : une nouvelle fonction de paroi, avec les mêmes arguments
que les autres, dans le fichier partagé.

```glsl
vec3 shop_surface(int face, vec2 m, vec2 extent, float soft, float shop_type, float r, out float fixture) {
```

- une épicerie : cinq tablettes, et sur chacune des paquets de largeurs et de teintes tirées. De
  loin, les paquets se fondent en une teinte moyenne ;
- un café : des lambris de bois, un comptoir sombre, l'ardoise du menu, et des suspensions
  rondes ;
- un magasin : des murs blancs, des niches éclairées, et dans chacune quelque chose de coloré.

Une boutique ouverte est éclairée en plein jour ; la nuit, trois sur dix ont fermé. Les cafés
ont une lumière chaude. Le sol d'une boutique est celui de la rue : le shader le retrouve par la
hauteur du bas de la vitre.

### 8. Le bronze, poli à hauteur de main

Un nouveau shader, pour le métal de l'entrée, des portes tambour et de la marquise. Le bronze à
l'air libre brunit, puis verdit par endroits. Là où les mains le touchent chaque jour, il reste
poli et doré. Le shader le sait par la hauteur :

```glsl
	float hands = smoothstep(hand_height.x - 0.1, hand_height.x, v_pos.y) * (1.0 - smoothstep(hand_height.y, hand_height.y + 0.15, v_pos.y));
	hands *= wear * (0.6 + 0.4 * pc_noise2(p * 8.0));
	col = mix(col, pc_color_in(polished_color), hands);
```

Entre 0,85 m et 1,35 m du sol, le métal est usé, frangé par un bruit fin. Le métal poli brille ;
la patine est mate. La position sert encore une fois à savoir où l'on est : ici, à hauteur de
main.

### 9. Les tours de verre

Leur hall vitré occupe tout le rez-de-chaussée : on y pose seulement deux portes tambour, sous la
marquise. Sur la place, devant la tour, quatre jardinières de granit plantées de buis, de part et
d'autre de l'allée qui mène à l'entrée.

### 10. Le dé de la tour

```gdscript
	_random.seed = 0
```

Les boutiques tirent leur sorte, leur nom, leurs teintes. Le dé repart toujours de la même
graine, au début de chaque construction : la tour est la même à chaque fois. L'étape 011 rendra
cette graine réglable.

## Ce qu'il faut retenir

1. La partie qu'on touche a son propre script, et ses propres règles de découpage.
2. Lancer le dé même quand le choix est imposé : le nombre de tirages ne dépend que de la
   géométrie.
3. Un `Label3D` écrit du vrai texte ; sa taille se règle par `pixel_size`.
4. Un matériau par teinte, partagé, plutôt qu'un matériau par objet.
5. La position dit où l'on est : à hauteur de main, le bronze est poli.

## À essayer

- Longer la tour au niveau de la rue, de jour puis de nuit.
- Dans la palette, ajouter un nom à une liste : il apparaît sur une enseigne.
- Dans le shader du bronze, `wear` à 0 : plus aucune trace de mains.
- Dans le script du rez-de-chaussée, `FASCIA` à 1,2 : de grandes enseignes.
- Dans le script de la tour, `_random.seed = 0` remplacé par `_random.seed = 5` : d'autres
  boutiques.
{TWIN}
## Étape suivante

011 : la graine. Un seul nombre, et la tour change : sa famille, son couronnement, ses
proportions, ses teintes, ses boutiques.
