class_name VisionComponent
extends Node3D
## Vision d'un acteur : une cible est vue si elle est assez proche, dans le cône devant lui (-Z local), et si aucun
## obstacle ne coupe la ligne de visée. Les obstacles sont les corps des couches de `obstacle_mask`.
## Entrées : can_see(). Réglages : posés dans la scène de l'acteur (valeurs tirées de ses données).

@export var range_max: float = 0.0
## Demi-angle du cône de vision, en degrés.
@export var half_angle: float = 0.0
@export_flags_3d_physics var obstacle_mask: int = 0


func can_see(target: Node3D) -> bool:
	var to_target := target.global_position - global_position
	if to_target.length() > range_max:
		return false
	var forward := -global_basis.z
	if forward.angle_to(to_target) > deg_to_rad(half_angle):
		return false
	var query := PhysicsRayQueryParameters3D.create(global_position, target.global_position, obstacle_mask)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
