extends GdUnitTestSuite
## Règles de la bombe : elle explose après son délai, à l'endroit où elle se trouve, et disparaît ;
## dans l'eau, l'explosion soulève une vague.

const SCENE_BOMBE := "res://3_entities/items/bomb/bomb.tscn"
const SCENE_EXPLOSION := "res://3_entities/items/bomb/explosion/explosion.tscn"
const SurfaceTemoin := preload("res://7_tests/1_core/water/surface_temoin.gd")


func after_test() -> void:
	for explosion in _explosions():
		explosion.free()


func _explosions() -> Array[Node]:
	return get_tree().root.get_children().filter(func(n: Node) -> bool: return n.scene_file_path == SCENE_EXPLOSION)


func _bombe(delai: float) -> RigidBody3D:
	var bombe: RigidBody3D = load(SCENE_BOMBE).instantiate()
	bombe.explosion_delay = delai
	bombe.freeze = true
	bombe.position = Vector3(3, 4, 5)
	add_child(bombe)
	return bombe


func test_avant_son_delai_la_bombe_attend() -> void:
	var bombe := _bombe(0.5)
	await await_millis(200)
	assert_bool(is_instance_valid(bombe)).is_true()
	assert_array(_explosions()).is_empty()
	bombe.free()


func test_apres_son_delai_elle_explose_sur_place_et_disparait() -> void:
	var bombe := _bombe(0.2)
	await await_millis(500)
	assert_bool(is_instance_valid(bombe)).is_false()
	var explosions := _explosions()
	assert_int(explosions.size()).is_equal(1)
	assert_vector((explosions[0] as Node3D).global_position).is_equal_approx(Vector3(3, 4, 5), Vector3.ONE * 0.001)


func test_dans_l_eau_l_explosion_fait_une_vague_a_sa_place() -> void:
	var ocean: WaterSurface = auto_free(SurfaceTemoin.new())
	ocean.hauteur = func(_p: Vector3) -> float: return 10.0
	add_child(ocean)
	_bombe(0.2)
	await await_millis(500)
	assert_int(ocean.vagues.size()).is_equal(1)
	assert_vector(ocean.vagues[0][0]).is_equal_approx(Vector3(3, 4, 5), Vector3.ONE * 0.001)


func test_hors_de_l_eau_l_explosion_ne_fait_pas_de_vague() -> void:
	var ocean: WaterSurface = auto_free(SurfaceTemoin.new())
	ocean.hauteur = func(_p: Vector3) -> float: return -100.0
	add_child(ocean)
	_bombe(0.2)
	await await_millis(500)
	assert_array(ocean.vagues).is_empty()
	assert_int(_explosions().size()).is_equal(1)
