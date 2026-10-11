class_name WeaponStats
extends Resource
## Définition d'une arme : cadence, dégâts, vitesse et durée de vie du projectile. Le projectile
## lui-même (une scène de 3_entities) est fourni à l'arme par le niveau.

## Identifiant stable, en snake_case, jamais renommé (DAT-06).
@export var id: StringName
@export var damage: int = 0
## Tirs par seconde.
@export var fire_rate: float = 0.0
@export var projectile_speed: float = 0.0
@export var lifetime: float = 0.0


## Erreurs de la définition (DAT-07) ; vide si elle est valide.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).is_empty() or String(id) != String(id).to_snake_case():
		errors.append("%s : id « %s » vide ou hors snake_case" % [resource_path, id])
	if damage <= 0 or fire_rate <= 0.0 or projectile_speed <= 0.0 or lifetime <= 0.0:
		errors.append("%s : dégâts, cadence, vitesse et durée de vie doivent être > 0" % resource_path)
	return errors
