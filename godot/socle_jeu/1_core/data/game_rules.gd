class_name GameRules
extends Resource
## Règles de la partie et rythme du déroulé : vies, durées des cinématiques, délai de fin de niveau.

## Identifiant stable, en snake_case, jamais renommé (DAT-06).
@export var id: StringName
@export var start_lives: int = 0
@export var intro_duration: float = 0.0
@export var ending_duration: float = 0.0
## Délai entre la fin d'un niveau (victoire ou défaite) et l'étape suivante.
@export var level_end_delay: float = 0.0


## Erreurs de la définition (DAT-07) ; vide si elle est valide.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).is_empty():
		errors.append("%s : id vide" % resource_path)
	if start_lives <= 0:
		errors.append("%s : start_lives %d (attendu > 0)" % [resource_path, start_lives])
	if intro_duration < 0.0 or ending_duration < 0.0 or level_end_delay < 0.0:
		errors.append("%s : durée négative" % resource_path)
	return errors
