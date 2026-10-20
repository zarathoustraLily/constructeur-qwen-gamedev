class_name WaterBuoyancySensor extends Marker3D
## Capteur de flottaison : un point qui lit, à chaque pas de physique, la hauteur de l'eau à sa verticale
## sur la surface d'eau de la scène (WaterSurface du groupe « ocean »). Sans surface, l'eau reste
## à la hauteur `water_height` qu'on lui donne.

## Hauteur (m) du volume du capteur : il est « sous l'eau » quand la surface le dépasse de cette hauteur.
@export var height: float = 1.0
## Multiplicateur de la poussée de ce capteur (lu par BuoyantBody3D).
@export var buoyancy_multiplier: float = 1.0

## Surface d'eau lue ; par défaut, la première du groupe « ocean ».
var ocean_node : WaterSurface

func _ready() -> void:
	if !ocean_node:
		ocean_node = get_tree().get_first_node_in_group("ocean")

## Hauteur de la surface à la verticale du capteur, au dernier pas de physique.
var water_height: float = 0.0
## Inutilisée : la normale se calcule avec compute_normal().
var water_normal: Vector3 = Vector3.UP
## Inutilisée.
var water_force: Vector3 = Vector3.ZERO


## Vrai si la surface est au niveau du capteur ou au-dessus.
func is_in_water() -> bool:
	return water_height >= global_position.y    

## Vrai si la surface dépasse le capteur d'au moins `height`.
func is_under_water() -> bool:
	return water_height >= global_position.y + height

## Vrai si le capteur est dans l'eau sans être dessous : il est à la surface.
func is_on_water() -> bool:
	return is_in_water() and not is_under_water()


## Hauteur de la surface à la verticale du capteur.
func get_water_height() -> float:
	return water_height
	
## Hauteur du capteur au-dessus de la surface : négative quand il est sous l'eau.
func get_water_depth() -> float:
	return global_position.y - water_height 

func _physics_process(_delta: float) -> void:
	if ocean_node:
		water_height = ocean_node.get_wave_height(global_position, 3, 5)
		
## Normale de la surface à la verticale du capteur, estimée par différences sur 10 cm ;
## verticale sans surface d'eau.
func compute_normal() -> Vector3:
	if ocean_node:
		var offset: float = 0.1
		var dx: float = (ocean_node.get_wave_height(global_position + Vector3(offset,0,0), 3, 5) - water_height) / offset;
		var dz: float = (ocean_node.get_wave_height(global_position + Vector3(0,0,offset), 3, 5) - water_height) / offset;
		return Vector3(-dx, 1.0, -dz).normalized();
		
	else: 
		return Vector3(0, 1, 0)
