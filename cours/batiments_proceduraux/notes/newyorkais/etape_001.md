# New York · étape 001 · Une tour : piliers et bandeaux

**Piste : Building.** On fabrique de la géométrie, rien d'autre. Pas encore de matériau
calculé, pas encore de fenêtre.

Ce qu'on obtient : une tour de bureaux aux proportions de Manhattan dans les années 1920.
13 travées de 2 m sur la façade principale et 9 sur les côtés, soit un plan de 26 m sur 18 m ;
30 étages de 3,66 m (12 pieds), soit 110 m de haut ; une grille de piliers et de bandeaux sur
les quatre faces ; un noyau sombre derrière.

## Ouvrir le projet

1. Dans Godot 4.7.2, importer ce dossier (le fichier `project.godot`).
2. F5 : la tour, cadrée en entier. Clic droit maintenu et souris : regarder. ZQSD : se
   déplacer. A et E : descendre, monter. Maj : aller vite. F : recadrer. Échap : quitter.
3. Pour régler la tour : ouvrir `{NAME}.tscn`, cliquer sur le nœud racine, changer une
   variable dans l'inspecteur. La tour se reconstruit aussitôt, sans lancer le jeu.

## Les fichiers du projet

{FILES_TABLE}

Le seul fichier à étudier à cette étape est `{NAME}.gd`. Les autres font tourner la visite :
ils sont les mêmes dans tous les projets du cours.

Les dossiers `0_autoload`, `3_entities` et `5_data` sont vides : un fichier `LISEZMOI.md` y dit
pourquoi.

## Ce qu'on a fait, dans l'ordre

### 1. Fixer le repère une fois pour toutes

Avant d'écrire une ligne, on décide où est la tour dans son propre espace. Cette décision ne
changera plus jusqu'à la dernière étape :

- la façade principale est dans le plan `z = 0` et regarde vers `+Z`, c'est-à-dire vers la rue ;
- elle est centrée sur `x = 0` ;
- le sol est à `y = 0` ;
- la tour s'enfonce vers `-Z` ;
- une unité vaut un mètre.

Une tour a quatre façades, et elles se ressemblent. On ne les écrit pas quatre fois : chacune
est décrite dans **son propre repère**, où elle est dans le plan `z = 0`, regarde vers `+Z` et
est centrée sur `x = 0`, exactement comme la façade principale. Le repère est ensuite tourné
et posé à sa place :

```gdscript
	var faces: Array[Transform3D] = [
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 0.0)),
		Transform3D(Basis(Vector3.UP, 0.5 * PI), Vector3(0.5 * width, 0.0, -0.5 * depth)),
		Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, -depth)),
		Transform3D(Basis(Vector3.UP, -0.5 * PI), Vector3(-0.5 * width, 0.0, -0.5 * depth)),
	]
	for index: int in range(faces.size()):
		var bays: int = bay_count if index % 2 == 0 else side_bay_count
		_build_face(wall, faces[index], bays, height)
```

Devant, à droite, derrière, à gauche : un quart de tour de plus à chaque fois. Un
`Transform3D`, c'est une rotation (`Basis`) et une position. La même fonction
`_build_face()` monte les quatre façades ; seuls changent le repère et le nombre de travées.

### 2. Déclarer les variables

Chaque `@export` devient un réglage dans l'inspecteur. Il y en a huit, rangés en trois groupes
par `@export_group` :

- **Plan** : `bay_count`, `side_bay_count`, `bay_width` ;
- **Niveaux** : `floor_count`, `floor_height` ;
- **Baies** : `window_width`, `window_height`, `sill_height`.

`@export_range(2, 30, 1)` borne la valeur et donne un curseur. `"suffix:m"` affiche l'unité.
Le commentaire `##` placé au-dessus d'une variable devient son aide au survol.

C'est ici, et seulement ici, que la tour est « de New York » :

| Variable | Valeur | Ce qu'elle dit |
|---|---|---|
| `bay_count`, `side_bay_count`, `bay_width` | 13 et 9 travées de 2 m | un plan de 26 m sur 18 m |
| `floor_count`, `floor_height` | 30 étages de 3,66 m | 12 pieds de plancher à plancher : 110 m de haut |
| `window_width`, `window_height` | 1,20 m sur 1,90 m | des fenêtres plus hautes que larges |
| `sill_height` | 0,85 m | une allège de bureau |
| `WALL_DEPTH`, `PIER_PROJECTION` | 0,35 m et 0,12 m | un mur de brique épais, des piliers qui avancent |

Ces cotes sont plausibles pour une tour de bureaux des années 1920 ; elles ne sont pas relevées
sur une tour réelle.

### 3. Faire tourner le script dans l'éditeur

La première ligne, `@tool`, fait tourner le script dans l'éditeur, pas seulement dans le jeu.
C'est ce qui permet de voir la tour en réglant ses variables.

Il faut alors savoir quand reconstruire. On ne met pas de code sur chaque variable. À la place,
`_current_signature()` hache toutes les variables exportées en un seul nombre, et `_process()`
compare ce nombre à celui de la dernière construction. S'il a changé, on reconstruit. Dans le
jeu, `_ready()` coupe `_process()` : la tour est montée une seule fois.

```gdscript
func _process(_delta: float) -> void:
	# Dans l'éditeur, à chaque image : une variable a-t-elle changé dans l'inspecteur ?
	if _current_signature() != _signature:
		rebuild()
```

### 4. Écrire `rebuild()`, le chef d'orchestre

Toujours les mêmes quatre temps :

1. jeter l'ancien résultat ;
2. créer un nœud interne nommé `Generated` : il n'apparaît pas dans l'arbre de la scène et
   n'est pas enregistré avec elle. La scène ne garde donc que les variables ;
3. écrire les triangles dans des `SurfaceTool`, un par matériau : ici, la brique et le noyau ;
4. transformer chaque `SurfaceTool` en maillage avec `_commit()`.

### 5. Compter autrement : des piliers et des bandeaux

Un immeuble de Paris ou de Tokyo pose quatre boîtes autour de chaque fenêtre : deux trumeaux,
une allège, un linteau. L'idée reste la même ici : **on ne perce pas un mur, on pose du mur
autour des trous.** Mais une tour de 30 étages a 1 320 fenêtres : quatre boîtes par fenêtre
en feraient 5 280.

On compte donc autrement. Les fenêtres d'une tour sont alignées en colonnes et en rangées : on
pose **un pilier par travée**, d'un seul tenant du pied au sommet, et **un bandeau par étage**,
sur toute la largeur de la façade. Les fenêtres sont les vides qui restent entre eux.

```gdscript
	# Un pilier entre deux travées, sur toute la hauteur. Les piliers d'angle sont à part.
	for bay: int in range(1, bays):
		var x: float = -0.5 * width + float(bay) * bay_width
		_add_box_in(surface, frame, Vector3(pier, height, WALL_DEPTH + PIER_PROJECTION),
				Vector3(x, 0.5 * height, 0.5 * (PIER_PROJECTION - WALL_DEPTH)))
```

```gdscript
	for floor_index: int in range(floor_count):
		var sill_y: float = float(floor_index) * floor_height + sill_height
		var bottom: float = maxf(sill_y - (floor_height - opening.y), 0.0)
		_add_box_in(surface, frame, Vector3(width + WALL_OVERLAP, sill_y - bottom, WALL_DEPTH),
				Vector3(0.0, 0.5 * (bottom + sill_y), band_z))
```

Trois calculs à comprendre :

- `opening` : la taille de la fenêtre, rabotée par `minf()` pour qu'elle ne dépasse jamais sa
  case ;
- `pier = bay_width - opening.x` : la largeur d'un pilier, ce qui reste de la travée à côté de
  la fenêtre. Ici, 80 cm ;
- le bandeau d'un étage va du haut de la fenêtre de l'étage du dessous (`sill_y - (floor_height
  - opening.y)`) jusqu'au bas de la fenêtre de cet étage (`sill_y`). Un dernier bandeau ferme
  le sommet.

Le compte : par façade de devant, 12 piliers, 31 bandeaux et un pilier d'angle ; par côté, 8,
31 et 1. Les quatre façades font 168 boîtes ; avec le noyau, 169 boîtes de 12 triangles :
**2 028 triangles**, au lieu de plus de 60 000.

Les piliers sont plus épais que les bandeaux : ils avancent de 12 cm (`PIER_PROJECTION`)
devant eux. C'est ce qui donne à la tour sa verticalité, celle des gratte-ciel de cette époque.

### 6. Les angles

Au bout d'une façade, il reste une demi-largeur de pilier avant la première fenêtre ; la façade
voisine a la même au même coin. Un pilier d'angle prend les deux : vu de dessus, c'est un carré
de côté `corner` qui enveloppe le coin, et qui avance comme les autres piliers sur les deux
façades. Chaque façade pose celui de son bout gauche ; à la quatrième, les quatre coins sont
faits.

```gdscript
	var corner: float = 0.5 * pier + PIER_PROJECTION
	_add_box_in(surface, frame, Vector3(corner, height, corner),
			Vector3(-0.5 * width - PIER_PROJECTION + 0.5 * corner, 0.5 * height, PIER_PROJECTION - 0.5 * corner))
```

### 7. Une boîte dans le repère d'une façade : `_add_box_in()`

Une boîte est décrite par sa taille et son centre dans le repère de sa façade. Pour la poser,
on transforme son centre (`frame * center`). Et sa taille ? Les façades sont tournées d'un
quart de tour exact : une boîte y reste une boîte droite, dont la largeur et la profondeur
s'échangent. `frame.basis * size` fait cet échange (avec des signes, que `abs()` efface).

```gdscript
func _add_box_in(surface: SurfaceTool, frame: Transform3D, size: Vector3, center: Vector3) -> void:
	var turned: Vector3 = (frame.basis * size).abs()
	_add_box(surface, turned, frame * center)
```

### 8. Descendre jusqu'au triangle

Quatre petites fonctions, chacune bâtie sur la suivante :

- `_add_box()` : six rectangles, deux par axe. La double boucle sur `axis` et `direction` évite
  d'écrire les six faces à la main ;
- `_add_quad()` : deux triangles qui partagent une diagonale ;
- `_add_triangle()` : trois sommets, chacun avec sa normale. Godot prend pour face avant celle
  dont les sommets tournent dans le sens des aiguilles d'une montre. Un produit vectoriel
  comparé à la normale dit dans quel sens tourne le triangle ; s'il tourne à l'envers, on
  échange deux sommets ;
- `_commit()` : le `SurfaceTool` devient un maillage, porté par un `MeshInstance3D`, avec son
  matériau.

Les morceaux de mur voisins se recouvrent de 6 mm (`WALL_OVERLAP`) : posés bord à bord, ils
laisseraient passer un liseré de lumière à leur jonction.

### 9. Le noyau

Une dernière boîte, en retrait d'un mètre derrière les façades, sur toute la hauteur. C'est
elle qu'on voit par les fenêtres, tant qu'il n'y a ni vitre ni bureau derrière : un gris presque
noir, son propre `SurfaceTool`, son propre matériau.

## Ce qu'il faut retenir

1. Un maillage procédural est une liste de triangles écrite dans un `SurfaceTool`.
2. On pose du mur autour des trous, mais on choisit les morceaux selon l'objet : à l'échelle
   d'une tour, des piliers et des bandeaux continus, pas quatre boîtes par fenêtre.
3. Le repère et l'unité sont fixés avant tout le reste. Une façade, quatre repères.
4. La scène n'enregistre que des variables ; la géométrie est refaite à chaque ouverture.
5. À ce stade, le style n'est pas dans le code : il est dans les nombres.

## À essayer

- `floor_count` à 80 : 293 m de haut. Le nombre de triangles n'augmente que de 50 bandeaux par
  façade.
- `bay_count` et `side_bay_count` à 4 : une tour « crayon ».
- `window_width` à 2,4 : la fenêtre est rabotée à 1,70 m, et le pilier tombe à 30 cm.
- Dans le script, `PIER_PROJECTION` à 0 : la façade devient une grille plate, et la tour perd
  sa verticalité.
- Dans `_add_triangle()`, retirer l'échange des sommets : une partie des faces disparaît,
  parce qu'elles sont vues de dos.
{TWIN}
## Étape suivante

002 : la brique, un shader calculé pixel par pixel. Et les fonctions `_add_triangle`,
`_add_quad`, `_add_box` et `_commit` partent dans un outil commun, pour ne plus les recopier.
