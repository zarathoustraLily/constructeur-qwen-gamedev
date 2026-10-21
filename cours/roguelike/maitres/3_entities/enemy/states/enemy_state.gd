class_name EnemyState extends State
## Classe de base des états d'un ennemi : ils le déplacent, le tournent vers sa cible, et passent à la chute
## quand le sol manque.

## L'ennemi piloté.
@export var enemy: Enemy
## L'état de chute.
@export var fall_state: EnemyState


## Avance dans `direction` (au sol, de longueur 1) à `speed` ; sans direction, ralentit jusqu'à l'arrêt ; repoussé,
## suit son recul. Puis, sans sol sous les pieds, passe à la chute.
func move_enemy(speed: float, direction: Vector3) -> void:
	if not direction.is_zero_approx():
		enemy.velocity.x = direction.x * speed
		enemy.velocity.z = direction.z * speed
	else:
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, speed)
		enemy.velocity.z = move_toward(enemy.velocity.z, 0.0, speed)
	if enemy.knockback_component.is_active():
		enemy.velocity = enemy.knockback_component.magnitude
	enemy.move_and_slide()
	if not enemy.is_on_floor():
		finished.emit(fall_state.name)


## Tourne le modèle vers la cible, s'il y en a une.
func look_at_target() -> void:
	if enemy.target != null:
		look_at_point(enemy.target.global_position)


## Tourne le modèle vers `point`, à l'horizontale ; rien si le point est sous ses pieds.
func look_at_point(point: Vector3) -> void:
	point.y = enemy.mesh_mount.global_position.y
	if point.is_equal_approx(enemy.mesh_mount.global_position):
		return
	enemy.mesh_mount.look_at(point, Vector3.UP, true)
