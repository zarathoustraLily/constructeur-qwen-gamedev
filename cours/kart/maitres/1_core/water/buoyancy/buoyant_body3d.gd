class_name BuoyantBody3D extends RigidBody3D
## Corps rigide qui flotte : chaque capteur WaterBuoyancySensor enfant passé sous la surface le pousse
## vers le haut, d'autant plus fort qu'il est profond, et le corps est freiné tant qu'il est immergé.

## Multiplicateur de la poussée de tous les capteurs.
@export var buoyancy_multiplier := 1.0
## Exposant de la profondeur dans la poussée : plus il est grand, plus la poussée croît vite avec la profondeur.
@export_range(0.5, 10.0, 0.001) var buoyancy_power := 1.5
## Part de la vitesse perdue à chaque pas de physique quand le corps est immergé.
@export var submerged_drag_linear := 0.05
## Part de la vitesse de rotation perdue à chaque pas de physique quand le corps est immergé.
@export var submerged_drag_angular := 0.1

## Vrai si au moins un capteur est sous la surface (mis à jour à chaque pas de physique).
var submerged := false
## Nombre de capteurs sous la surface.
var submerged_probes := 0
var _buoyancy_sensors : Array[WaterBuoyancySensor] = []

func _ready() -> void:
	_buoyancy_sensors.clear()
	for child in get_children(true):
		if child is WaterBuoyancySensor:
			_buoyancy_sensors.append(child)

func _physics_process(delta:float) -> void:
	var gravity : Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
	submerged_probes = 0
	submerged = false
	
	for sensor in _buoyancy_sensors:
		var depth := sensor.get_water_depth();
		var buoyancy: float = pow(abs(depth), buoyancy_power)
		
		if depth < 0.0:
			submerged = true
			submerged_probes += 1
			var force:Vector3 = -gravity * buoyancy * buoyancy_multiplier * sensor.buoyancy_multiplier * delta
			
			apply_force(force, sensor.global_position - global_position)

func _integrate_forces(_state:PhysicsDirectBodyState3D) -> void:
	if submerged:
		linear_velocity *= 1.0 - submerged_drag_linear
		angular_velocity *= 1.0 - submerged_drag_angular
