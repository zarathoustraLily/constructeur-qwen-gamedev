# New York · étape 012 · Le quartier : avenue, rues, deux règlements

**Piste : Variation.** Une tour seule ne fait pas Manhattan. On pose un quartier d'affaires :
une avenue du sud au nord, des rues transversales, des îlots de 200 pieds, et une tour sur chaque
terrain, chacune avec sa graine. Les trois familles se côtoient, chacune sous son règlement. Au
sol : la chaussée, les trottoirs, les passages piétons, des lampadaires, des feux, une cheminée
de vapeur et une entrée de métro.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5 : on est sur le trottoir de l'avenue, à hauteur
d'homme, le regard vers le nord. Clic droit et ZQSD pour marcher ; E pour monter au-dessus des
toits. Appuyer sur **N** : la nuit tombe sur tout le quartier. La seconde scène de visite,
`step_viewer_tours.tscn`, montre toujours les trois familles côte à côte.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. Le nouveau script est `…_quartier.gd`. Le script
de la tour ne change pas : le quartier s'en sert tel quel.

## Ce qu'on a fait, dans l'ordre

### 1. Le quartier a la même ossature que la tour

Un nœud `@tool`, des variables exportées, une empreinte des variables qui déclenche la
reconstruction, un nœud interne `Generated` qui reçoit tout ce que le script fabrique. Rien de
neuf : c'est la forme de tous les scripts procéduraux du cours.

| Variable | Défaut | Ce qu'elle dit |
|---|---|---|
| `block_count` | 4 | îlots le long de l'avenue |
| `avenue_width`, `street_width` | 100 et 60 pieds | d'un alignement à l'autre, trottoirs compris |
| `block_depth` | 200 pieds | un îlot, d'une rue à l'autre |
| `sidewalk_width` | 15 pieds | pris dans la largeur des rues |
| `avenue_lot_depth` | 45 m | les terrains sur l'avenue |
| `through_lot_width` | 40 m | les terrains traversants, derrière eux |
| `district_seed` | 0 | la graine du quartier |

Les valeurs par défaut viennent de la palette de `5_data` : la trame de 1811, déjà là depuis
l'étape 006, et la largeur des trottoirs, une cote plausible, non relevée.

### 2. La trame : quelques fonctions de mesure

L'avenue court le long de `z`, le nord vers `-Z` ; `x = 0` est son axe. Le pas de la trame le long
de l'avenue est un îlot plus une rue :

```gdscript
func _pitch() -> float:
	return block_depth + street_width
```

```gdscript
func _block_south(block: int) -> float:
	return block_depth + 0.5 * street_width - float(block) * _pitch()
```

Tout le reste se mesure à partir de là : le bord sud d'un îlot, l'axe de la rue au nord, la
profondeur des terrains. Quelques petites fonctions bien nommées valent mieux que des calculs
répétés dans tout le script.

### 3. Deux terrains par côté d'îlot

Chaque îlot porte, de chaque côté de l'avenue, deux terrains :

- **un terrain sur l'avenue**, entre deux rues. Sa façade de devant est l'alignement de l'avenue :
  sa tour regarde l'avenue. Ses deux côtés donnent sur les rues transversales ; derrière lui, le
  terrain traversant ;
- **un terrain traversant**, derrière lui, d'une rue à l'autre. Sa tour regarde la rue au nord ;
  ses deux côtés sont mitoyens.

Le quartier ne calcule aucune forme de tour : il pose des terrains, et donne à chacun ses rues.

```gdscript
			var tower: Node3D = _new_tower(index, block_depth, avenue_lot_depth)
			tower.set("street_front", avenue_width)
			tower.set("street_left", street_width)
			tower.set("street_right", street_width)
			tower.set("street_back", 0.0 if through_lot_width > 0.0 else street_width)
			tower.transform = Transform3D(Basis(Vector3.UP, -side * 0.5 * PI), front)
			_root.add_child(tower)
```

Une tour du côté ouest de l'avenue est tournée d'un quart de tour pour regarder vers l'est, celle
du côté est d'un quart de tour dans l'autre sens : `-side * 0.5 * PI`, avec `side` à -1 ou 1. La
tour traversante, elle, fait un demi-tour pour regarder vers le nord.

Chaque tour applique ensuite **elle-même** son règlement, avec ses rues : une tour de brique sur
l'avenue, large de 100 pieds, monte droit plus haut qu'une tour sur une rue de 60 pieds ; une tour
de verre recule de 10 pieds de l'avenue, de 15 pieds d'une rue. C'est tout l'intérêt d'avoir
écrit le règlement dans la tour : le quartier n'a rien à en savoir.

### 4. Une tour, c'est un script et des valeurs

```gdscript
func _new_tower(index: int, width: float, depth: float) -> Node3D:
	var tower: Node3D = Tower.new()
	tower.name = "Tour%02d" % index
	tower.set("lot_width", width)
	tower.set("lot_depth", depth)
	tower.set("variation_seed", district_seed * 1000 + index * 17 + 1)
	tower.set("family_choice", 0)
	tower.set("crown_choice", 0)
	tower.set("window_lights", 0)
	tower.set("random_massing", true)
	tower.set("random_colors", true)
	return tower
```

`Tower.new()` crée un nœud qui porte le script de la tour, sans scène. On règle ses variables
**avant** de l'ajouter à l'arbre : en y entrant, la tour appelle `_ready()`, puis `rebuild()`, et
se construit d'après ses variables. Les régler après ferait construire chaque tour deux fois.

Chaque tour a sa propre graine, tirée de celle du quartier et de son numéro. Tout est laissé au
hasard : famille, couronnement, petits bois, proportions, teintes. Changer `district_seed` change
tout le quartier ; deux quartiers de même graine sont identiques.

### 5. Le sol

La chaussée est une grande dalle sombre, un peu plus basse que les trottoirs. Les trottoirs sont
les îlots, élargis de la largeur d'un trottoir du côté de l'avenue et des rues : les tours sont
posées dessus, et leur tranche fait la bordure. Leur dallage de béton, en dalles de cinq pieds,
est encore le shader de la brique, couché, avec d'autres nombres.

Le mobilier, ensuite, fait de ce qu'on connaît : des cônes et des boîtes.

- **les passages piétons** : des bandes blanches parallèles à la circulation, de part et d'autre
  de chaque carrefour ;
- **les lampadaires** : un mât, une crosse qui avance au-dessus de la chaussée, une lanterne qui
  s'allume la nuit, environ tous les 30 m le long de l'avenue ;
- **les feux** : un poteau et un boîtier jaune au coin de chaque îlot ;
- **la cheminée de vapeur**, rayée orange et blanc, plantée sur la chaussée : elle évacue au-dessus
  des têtes la vapeur du réseau qui court sous Manhattan ;
- **l'entrée de métro** : la trémie de l'escalier, bordée d'une rambarde de fonte, et deux globes
  verts sur leurs poteaux, allumés jour et nuit.

### 6. La nuit, pour tout le quartier

```gdscript
func set_night(value: float) -> void:
	_night = value
	if _root == null:
		return
	for child: Node in _root.get_children():
		if child.has_method("set_night"):
			child.call("set_night", value)
```

Le quartier passe la nuit à chacune de ses tours, puis règle la force de ses lanternes et de ses
globes. `has_method()` demande à un nœud s'il sait faire quelque chose : les tours le savent, les
maillages du sol non.

### 7. Le test vérifie seize tours

Le test de l'étape 006 cherchait toutes les tours sous le nœud qu'on lui donne. Il les trouve donc
dans le quartier, sans une ligne de plus : seize tours, chacune sous son règlement, sa part du
terrain et son coefficient.

## Ce qu'il faut retenir

1. Un objet procédural bien fait sert de brique à un plus grand : le quartier se sert de la tour
   sans rien savoir de son règlement.
2. Régler les variables d'un nœud avant `add_child()` : il se construit une seule fois.
3. Une graine de quartier donne une graine par tour : tout le quartier se refait à l'identique.
4. Le sol et le mobilier sont faits des mêmes formes que la tour : des boîtes, des cônes, et le
   shader de la brique.

## À essayer

- `district_seed` de 0 à 10.
- `block_count` à 8 : une avenue deux fois plus longue.
- `through_lot_width` à 0 : un seul rang de terrains, et les tours sur l'avenue reçoivent une rue
  derrière elles.
- `avenue_lot_depth` à 30 : des terrains moins profonds, des tours plus minces.
- N, puis monter au-dessus des toits.
{TWIN}
## Étape suivante

013 : la performance. Seize tours, c'est beaucoup à dessiner : les niveaux de détail, une façade
lointaine dessinée sur un seul rectangle, et l'occultation.

## Sources

- Museum of the City of New York, *The Greatest Grid*, « The Commissioners' Plan, 1811 » : rues
  transversales de 60 pieds, avenues de 100 pieds, îlots de 200 pieds du nord au sud.
- La largeur des trottoirs, le format des dalles, les cotes du mobilier et la disposition des
  terrains sont des choix du cours, plausibles, non relevés.
