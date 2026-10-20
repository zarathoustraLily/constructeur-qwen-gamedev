extends Camera3D
## BPC_CameraTopDown.gd
## Caméra top-down qui suit le héros.

@export var heros: Node
@export var hauteur: float = 8.0
@export var angle: float = 45.0
@export var lerp_vitesse: float = 5.0


func _process(delta: float) -> void:
	if not heros or not is_instance_valid(heros):
		return
	var cible: Vector3 = heros.global_position
	cible.y = hauteur
	# Position en diagonale (top-down 45°)
	var offset: Vector3 = Vector3(0, hauteur, -hauteur * tan(deg_to_rad(angle)))
	var position_cible: Vector3 = cible + offset
	global_position = global_position.lerp(position_cible, lerp_vitesse * delta)
	look_at(cible)
