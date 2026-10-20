extends GdUnitTestSuite
## Règles de la bombe : elle explose au bout de son délai, laisse son explosion à sa place et disparaît ; dans
## l'eau, elle soulève une vague par la surface ; hors de l'eau, aucune.

const BOMB := preload("res://3_entities/items/bomb/bomb.tscn")
const SurfaceTemoin := preload("res://7_tests/1_core/water/surface_temoin.gd")

var _surface: WaterSurface


## Une surface d'eau témoin à hauteur `height`, puis une bombe posée en `position`.
func _bomb(height: float, position: Vector3) -> Bomb:
	_surface = auto_free(SurfaceTemoin.new())
	_surface.set("hauteur", func(_point: Vector3) -> float: return height)
	add_child(_surface)
	var bomb := BOMB.instantiate() as Bomb
	bomb.position = position
	bomb.gravity_scale = 0.0
	add_child(bomb)
	return bomb


func _explosions() -> Array[Node]:
	var found: Array[Node] = []
	for child: Node in get_children():
		if str(child.name).begins_with("Explosion"):
			found.append(child)
	return found


func test_elle_explose_au_bout_de_son_delai_et_laisse_son_explosion() -> void:
	var bomb := _bomb(-10.0, Vector3(3.0, 1.0, 0.0))
	var delay := bomb.explosion_delay
	for _frame: int in int((delay - 0.5) * 60.0):
		await get_tree().physics_frame
	assert_bool(is_instance_valid(bomb)).is_true()
	for _frame: int in 60:
		await get_tree().physics_frame
	assert_bool(is_instance_valid(bomb)).is_false()
	var explosions := _explosions()
	assert_int(explosions.size()).is_equal(1)
	assert_vector((explosions[0] as Node3D).global_position).is_equal_approx(Vector3(3.0, 1.0, 0.0), Vector3.ONE * 0.1)
	explosions[0].free()


func test_dans_l_eau_elle_souleve_une_vague() -> void:
	var bomb := _bomb(2.0, Vector3.ZERO)
	# Le signal physics_frame part avant que les nœuds ne jouent leur image : trois images pour que le capteur
	# ait lu la surface.
	for _frame: int in 3:
		await get_tree().physics_frame
	bomb.explode()
	var waves: Array[Array] = _surface.get("vagues")
	assert_int(waves.size()).is_equal(1)
	var height: float = waves[0][1]
	assert_float(height).is_greater(0.0)
	for explosion: Node in _explosions():
		explosion.free()


func test_hors_de_l_eau_aucune_vague() -> void:
	var bomb := _bomb(-10.0, Vector3.ZERO)
	await get_tree().physics_frame
	bomb.explode()
	assert_int((_surface.get("vagues") as Array).size()).is_equal(0)
	for explosion: Node in _explosions():
		explosion.free()
