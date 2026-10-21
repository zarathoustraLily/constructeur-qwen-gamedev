class_name Upgrade extends Resource
## Une amélioration de la boutique : la propriété du joueur qu'elle augmente (stat), de combien (bonus), et sa
## présentation (titre, description). Elle ne connaît pas la classe du joueur : elle lit et écrit la propriété par
## son nom. Une amélioration écrit dans l'état du joueur, jamais dans ses réglages (une ressource partagée, règle
## DAT-04). Un .tres par amélioration, dans 5_data/upgrades/.

## Le titre de la carte.
@export var title: String = ""
## La description, avec deux %f (ou %d) : la valeur actuelle, puis la valeur après l'amélioration ; du BBCode est
## permis.
@export_multiline var description_template: String = ""
## Le nom de la propriété augmentée chez le joueur.
@export var stat: StringName = &""
## Ce qu'on y ajoute.
@export var bonus: float = 0.0


## La valeur actuelle chez `target`.
func current_value(target: Node) -> float:
	return target.get(stat) as float


## Augmente la valeur chez `target` de bonus.
func apply(target: Node) -> void:
	target.set(stat, current_value(target) + bonus)


## La description pour `target` : sa valeur actuelle, puis la valeur après ; sans cible, le seul bonus.
func describe(target: Node) -> String:
	if target == null:
		return "+%s" % bonus
	return description_template % [current_value(target), current_value(target) + bonus]
