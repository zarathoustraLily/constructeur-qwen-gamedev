class_name KartWake extends Node
## Sillage du kart sur l'eau. À chaque pas de physique, si le kart flotte et roule assez vite, il ajoute à la
## surface d'eau que lit son capteur : une ondulation sous chaque roue, de l'écume sous les roues arrière, et
## une vague au milieu de l'essieu arrière. La vague d'impact entre dans la hauteur de l'eau : ce qui flotte
## derrière le kart la sent. Les réglages sont dans 5_data/kart/kart_wake.tres.

## Le kart qui laisse le sillage.
@export var kart: Kart
## Réglages du sillage.
@export var settings: KartWakeSettings


func _ready() -> void:
	if kart == null or settings == null:
		push_error("Sillage : kart ou réglages (settings) absents")
		set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if not kart.is_in_water() or kart.water_sensor.ocean_node == null:
		return
	var surface := kart.water_sensor.ocean_node
	var speed := kart.get_horizontal_velocity().length()
	if speed <= settings.min_speed:
		return
	var strength := settings.strength * lerpf(settings.min_strength, 1.0,
		clampf(inverse_lerp(settings.min_speed, settings.full_speed, speed), 0.0, 1.0))
	var water_height := kart.water_sensor.get_water_height()
	for offset: Vector3 in settings.front_wheels:
		surface.add_ripple(_on_water(offset, water_height), settings.ripple_height * strength, settings.ripple_radius_px)
	var rear_center := Vector3.ZERO
	for offset: Vector3 in settings.rear_wheels:
		var point := _on_water(offset, water_height)
		surface.add_ripple(point, settings.ripple_height * strength, settings.ripple_radius_px)
		surface.add_foam(point, settings.foam_amount * minf(strength, 1.0), settings.foam_radius)
		rear_center += point
	if not settings.rear_wheels.is_empty():
		surface.add_wave(rear_center / settings.rear_wheels.size(), settings.wake_height * strength,
			settings.wake_radius_px)


## Le point du kart `offset` (dans son repère), posé à la hauteur de l'eau.
func _on_water(offset: Vector3, water_height: float) -> Vector3:
	var point := kart.global_transform * offset
	return Vector3(point.x, water_height, point.z)
