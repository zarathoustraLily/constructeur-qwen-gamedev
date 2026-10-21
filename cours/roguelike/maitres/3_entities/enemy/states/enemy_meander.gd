extends EnemyState
## Errance : l'ennemi choisit un but au hasard autour de lui (un point du maillage de navigation, tiré avec son
## RandomNumberGenerator) et s'y rend ; arrivé, ou la cible à portée, il se tourne vers elle et attaque.

## L'état d'attaque.
@export var attack_state: EnemyState

var _has_destination: bool = false


## Lance la course ; le but se choisit dès que la navigation est prête.
func enter(_previous_state: StringName) -> void:
	enemy.animation_tree.change_immediate(&"WalkSpace")
	enemy.animation_tree.blend_target = 1.0
	_has_destination = false


## La cible à portée, attaque ; sinon choisit son but, dès que la carte de navigation a été calculée une première
## fois ; arrivé, attaque ; sinon, avance vers le prochain point du chemin.
func physics_update(_delta: float) -> void:
	if enemy.distance_to_target() <= enemy.settings.attack_range:
		_attack()
		return
	if not _has_destination:
		# Avant sa première synchronisation, la carte ne répond pas (« query failed […] before first map
		# synchronization ») : on attend.
		if NavigationServer3D.map_get_iteration_id(enemy.get_world_3d().navigation_map) == 0:
			return
		enemy.navigation_agent.target_position = random_destination()
		_has_destination = true
	if enemy.navigation_agent.is_navigation_finished():
		_attack()
		return
	var destination := enemy.navigation_agent.get_next_path_position()
	look_at_point(destination)
	var direction := destination - enemy.global_position
	direction.y = 0.0
	move_enemy(enemy.settings.speed, direction.normalized())


## Un point du maillage de navigation, tiré à moins de meander_radius de l'ennemi : un angle et une distance au
## hasard (avec la graine de l'ennemi), puis le point du maillage le plus proche.
func random_destination() -> Vector3:
	var angle := enemy.rng.randf_range(0.0, TAU)
	var distance := enemy.rng.randf_range(0.0, enemy.settings.meander_radius)
	var candidate := enemy.global_position + Vector3(cos(angle), 0.0, sin(angle)) * distance
	return NavigationServer3D.map_get_closest_point(enemy.get_world_3d().navigation_map, candidate)


func _attack() -> void:
	look_at_target()
	finished.emit(attack_state.name)
