# Paris · étape 006 · Niveaux : soubassement, étage noble, dernier étage

**Piste : Building.** Jusqu'ici la façade était une grille : cinq niveaux identiques. Un
immeuble parisien est une superposition de niveaux différents : un soubassement, un étage
noble, des étages courants, un dernier étage, une corniche. Cette étape remplace la grille par
une **liste de niveaux**.

## Ouvrir le projet

Importer `project.godot` dans Godot 4.7.2, puis F5. Pour régler l'immeuble, ouvrir
`{NAME}.tscn` : le groupe « Niveaux » a changé, un groupe « Façade » est apparu.

## Les fichiers du projet

{FILES_TABLE}

Dans la colonne Fichier, `…` remplace `{NAME}`. L'essentiel est dans le script de l'immeuble.
Le shader de pierre gagne les refends ; le script des matériaux, une seconde pierre.

## Ce qu'on a fait, dans l'ordre

### 1. De nouvelles variables : décrire, pas dessiner

`floor_count` et `floor_height` décrivaient une grille. Ils sont remplacés par des variables
qui décrivent un immeuble :

| Variable | Défaut | Niveau |
|---|---|---|
| `ground_height` | 4,10 m | rez-de-chaussée |
| `entresol`, `entresol_height` | oui, 2,70 m | entresol, au-dessus du rez-de-chaussée |
| `noble_height` | 3,70 m | étage noble, le plus haut sous plafond |
| `floor_count`, `floor_height` | 2 étages de 3,15 m | étages courants |
| `top_floor`, `top_floor_height` | oui, 2,95 m | dernier étage |

`window_height` et `sill_height` ont disparu : chaque niveau calcule la hauteur de ses baies
d'après sa propre hauteur.

### 2. Une donnée intermédiaire : la classe `Level`

Le pas important de l'étape. Entre les variables et la géométrie, on glisse une description :

```gdscript
class Level:
	var height: float = 3.0
	var opening: Vector2 = Vector2(1.3, 2.3)   # largeur et hauteur de la baie
	var sill: float = 0.1                       # hauteur de l'allège
	var base: bool = false                      # niveau de soubassement
```

Une classe déclarée à l'intérieur d'un script, qui ne contient que des données. Elle ne sait
rien dessiner.

### 3. Traduire les variables en niveaux : `_make_levels()`

Cette fonction lit les variables et renvoie un tableau de `Level`, du rez-de-chaussée au
dernier étage. C'est là, et seulement là, que sont écrites les règles de composition :

- le rez-de-chaussée et l'entresol sont du soubassement (`base = true`) ;
- les baies du rez-de-chaussée sont placées haut : allège d'un mètre ;
- les étages courants ont des baies un peu plus étroites que l'étage noble, le dernier étage
  encore un peu plus ;
- aux étages, l'allège vaut 10 cm : ce sont des portes-fenêtres.

### 4. Monter un niveau : `_build_level()` change de signature

```gdscript
# étapes 002 à 005
func _build_level(level: int) -> void:
# à partir de l'étape 006
func _build_level(level: Level, index: int, base_y: float) -> float:
```

Elle ne reçoit plus un numéro mais une description. Et comme les niveaux n'ont plus la même
hauteur, elle ne peut plus calculer sa hauteur de départ par une multiplication : elle la
reçoit (`base_y`) et renvoie celle du niveau suivant. Dans `rebuild()` :

```gdscript
var base_y: float = 0.0
for index: int in range(levels.size()):
	base_y = _build_level(levels[index], index, base_y)
```

À l'intérieur, le principe de l'étape 001 n'a pas bougé : deux trumeaux, une allège, un
linteau, puis le rectangle de la fenêtre.

### 5. Deux pierres pour un seul shader

Le soubassement est en pierre à refends : des rainures horizontales. Les étages sont en
pierre lisse. `_build_level()` choisit :

```gdscript
var wall_material: ShaderMaterial = _materials.stone_base if level.base else _materials.stone
```

Dans le script des matériaux, `stone_base` sort du **même shader** que `stone`, avec d'autres
nombres : assises plus hautes, blocs plus longs, refends, un peu plus de suie.

Dans le shader, les refends sont la même recette que le relief des joints de l'étape 003 :
une rampe, sa pente, et la normale qui penche. Plus une ombre sous le bord supérieur de la
rainure.

### 6. Bandeaux et corniche : des boîtes

Entre deux niveaux, un bandeau : une boîte longue de toute la façade, haute de 20 cm, qui
déborde de 10 cm. En haut, `_build_cornice()` pose deux boîtes en encorbellement. C'est
sommaire, et c'est voulu : l'étape 008 remplacera ces boîtes par des moulures profilées, et
l'étape 013 les fera revenir pour les immeubles lointains.

## Ce qu'il faut retenir

1. Entre les variables et la géométrie, une description intermédiaire : ici, la liste des
   niveaux. Les règles de composition sont dans la fonction qui la fabrique, pas dans celle
   qui dessine.
2. Une fonction qui empile reçoit sa hauteur de départ et renvoie la suivante.
3. Un même shader donne plusieurs matières : on change ses nombres, pas son code.

## À essayer

- `entresol` décoché, `floor_count` à 4 : un immeuble de faubourg.
- `top_floor` décoché, `floor_count` à 0 : il ne reste que le soubassement et l'étage noble.
- `rusticated_base` décoché : le soubassement redevient lisse.
- `course_height` à 0,5 : de grandes assises.
- Dans `_make_levels()`, changer l'allège de l'entresol (`low.sill`) : la règle est à un seul
  endroit.
{TWIN}
## Étape suivante

007 : des balcons filants à l'étage noble et au dernier étage, et un shader qui dessine leurs
garde-corps de fer.
