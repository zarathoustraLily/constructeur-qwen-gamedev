class_name CameraInput extends Node
## L'entrée de la caméra : le stick droit (une vitesse, multipliée par le temps), la souris (un déplacement relatif,
## multiplié par la sensibilité), la visée et le verrouillage. Verrouiller choisit la cible la plus proche devant ;
## appuyer à nouveau déverrouille.

## La caméra pilotée.
@export var orbit: OrbitCamera


func _ready() -> void:
	process_physics_priority = ProcessOrder.INPUT


func _physics_process(delta: float) -> void:
	var stick: Vector2 = Input.get_vector(Actions.CAMERA_LEFT, Actions.CAMERA_RIGHT, Actions.CAMERA_UP, Actions.CAMERA_DOWN)
	var speed: float = deg_to_rad(orbit.settings.stick_degrees_per_second) * delta
	orbit.rotate_by(-stick.x * speed, stick.y * speed)
	orbit.aiming = Input.is_action_pressed(Actions.AIM)
	if Input.is_action_just_pressed(Actions.LOCK_ON):
		toggle_lock()


func _unhandled_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var step: float = deg_to_rad(orbit.settings.mouse_degrees_per_pixel)
		orbit.rotate_by(-motion.relative.x * step, motion.relative.y * step)


## Verrouille la cible la plus proche devant la caméra, ou déverrouille si une cible l'est déjà.
func toggle_lock() -> void:
	if orbit.locked != null:
		orbit.lock(null)
		return
	var candidates: Array[Node3D] = []
	for node: Node in get_tree().get_nodes_in_group(LockOn.GROUP):
		if node is Node3D:
			candidates.append(node as Node3D)
	orbit.lock(LockOn.pick(orbit.global_position, orbit.ground_forward(), candidates, orbit.settings.lock_range))
