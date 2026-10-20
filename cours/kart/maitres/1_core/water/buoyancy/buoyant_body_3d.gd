class_name BuoyantBody3D extends RigidBody3D
## Corps rigide qui flotte : chaque capteur WaterBuoyancySensor enfant passé sous la surface le pousse vers le
## haut, d'autant plus fort qu'il est profond, au point du capteur : un capteur décalé fait pencher le corps.
## Tant qu'il est immergé, le corps est freiné.

## Multiplicateur de la poussée de tous les capteurs.
@export var buoyancy_multiplier: float = 1.0
## Exposant de la profondeur dans la poussée : plus il est grand, plus la poussée croît vite avec la profondeur.
@export_range(0.5, 10.0, 0.001) var buoyancy_power: float = 1.5
## Part de la vitesse perdue à chaque pas de physique quand le corps est immergé.
@export var submerged_drag_linear: float = 0.05
## Part de la vitesse de rotation perdue à chaque pas de physique quand le corps est immergé.
@export var submerged_drag_angular: float = 0.1

## Vrai si au moins un capteur est sous la surface (mis à jour à chaque pas de physique).
var submerged: bool = false
## Nombre de capteurs sous la surface.
var submerged_probes: int = 0

var _buoyancy_sensors: Array[WaterBuoyancySensor] = []


func _ready() -> void:
	_buoyancy_sensors.clear()
	for child: Node in get_children(true):
		var sensor := child as WaterBuoyancySensor
		if sensor != null:
			_buoyancy_sensors.append(sensor)


func _physics_process(delta: float) -> void:
	var gravity: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
	submerged_probes = 0
	submerged = false
	for sensor: WaterBuoyancySensor in _buoyancy_sensors:
		var depth := sensor.get_water_depth()
		if depth < 0.0:
			submerged = true
			submerged_probes += 1
			var buoyancy := pow(absf(depth), buoyancy_power)
			var force := -gravity * buoyancy * buoyancy_multiplier * sensor.buoyancy_multiplier * delta
			apply_force(force, sensor.global_position - global_position)


func _integrate_forces(_state: PhysicsDirectBodyState3D) -> void:
	if submerged:
		linear_velocity *= 1.0 - submerged_drag_linear
		angular_velocity *= 1.0 - submerged_drag_angular
