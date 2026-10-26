class_name RobotStats
extends Resource
## Définition du robot, immuable pendant la partie : ses valeurs vivent dans 5_data/actors/robot.tres.

## Identifiant stable, en snake_case, jamais renommé.
@export var id: StringName
## Durée de l'étourdissement après un coup, en secondes.
@export var stun_duration: float = 0.0


## Erreurs de la définition ; vide si elle est valide.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).is_empty() or String(id) != String(id).to_snake_case():
		errors.append("%s : id « %s » vide ou hors snake_case" % [resource_path, id])
	if stun_duration <= 0.0:
		errors.append("%s : stun_duration %.2f (attendu > 0)" % [resource_path, stun_duration])
	return errors
