extends GdUnitTestSuite
## Règles du semeur de détails, sur un terrain plat de 20 m : sans masque, presque chaque point de la grille
## reçoit un détail ; une même graine donne le même semis, une autre graine un autre ; un masque vert
## n'en laisse aucun ; hors de la plage de hauteur, aucun ; chaque bloc est un MultiMeshInstance3D nommé
## DetailBlockNNN, rangé à son coin.
## Sans fenêtre, le moteur ne garde pas les transformations d'un MultiMesh : le semis se compare sur les
## transformations calculées par le semeur (chunk_transforms), avant leur envoi au MultiMesh.

const SIZE := 20.0
const CHUNK := Vector3(SIZE / 2.0, 200.0, SIZE / 2.0)
const CORNER := Vector3(-SIZE / 2.0, -100.0, -SIZE / 2.0)

var _populator: Node3D
var _terrain: StaticBody3D


func before_test() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())
	_terrain = StaticBody3D.new()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	_terrain.add_child(mesh_instance)
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	_terrain.add_child(shape)
	add_child(auto_free(_terrain))
	_populator = auto_free(load("res://1_core/tools/detail_populator.gd").new())
	_populator.set("collider", _terrain)
	_populator.set("terrain_mesh_instance", mesh_instance)
	_populator.set("terrain_texture", _mask(Color.BLACK))
	_populator.set("detail_grid_size", 1.0)
	_populator.set("detail_mesh", BoxMesh.new())
	_populator.set("rules_vertical_range", Vector2(-1.0, 1.0))
	_populator.set("bounds_size", Vector3(SIZE, 200.0, SIZE))
	_populator.set("bounds_center", Vector3.ZERO)
	_populator.set("bounds_subdivsion", Vector3i(2, 1, 2))
	add_child(_populator)


func _mask(color: Color) -> ImageTexture:
	var image := Image.create(8, 8, false, Image.FORMAT_RGB8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


## Attend que le terrain soit entré dans l'espace physique : les rayons du semeur le touchent ensuite.
func _wait_physics() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame


## Sème, puis rend les blocs créés (ceux d'un semis précédent partent à la fin de l'image).
func _populate() -> Array[MultiMeshInstance3D]:
	await _wait_physics()
	_populator.call("populate")
	var blocks: Array[MultiMeshInstance3D] = []
	for child: Node in _populator.get_children():
		if not child.is_queued_for_deletion():
			blocks.append(child as MultiMeshInstance3D)
	return blocks


func _count(blocks: Array[MultiMeshInstance3D]) -> int:
	var total := 0
	for block: MultiMeshInstance3D in blocks:
		total += block.multimesh.instance_count
	return total


## Les détails du premier bloc, tirés avec la graine `seed_value`.
func _transforms(seed_value: int) -> Array[Transform3D]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return _populator.call("chunk_transforms", CHUNK, CORNER, rng)


func test_sans_masque_presque_chaque_point_recoit_un_detail() -> void:
	var blocks: Array[MultiMeshInstance3D] = await _populate()
	assert_int(blocks.size()).is_equal(4)
	assert_int(_count(blocks)).is_between(300, 400)


func test_chaque_bloc_est_nomme_et_range_a_son_coin() -> void:
	var blocks: Array[MultiMeshInstance3D] = await _populate()
	var names: Array[String] = []
	for block: MultiMeshInstance3D in blocks:
		names.append(str(block.name))
		assert_float(block.position.x).is_in([-SIZE / 2.0, 0.0])
	assert_array(names).contains_exactly_in_any_order(["DetailBlock000", "DetailBlock001", "DetailBlock002",
		"DetailBlock003"])


func test_une_meme_graine_donne_le_meme_semis() -> void:
	await _wait_physics()
	_populator.call("load_terrain")
	var first := _transforms(0)
	assert_int(first.size()).is_greater(50)
	assert_array(_transforms(0)).is_equal(first)
	assert_array(_transforms(7)).is_not_equal(first)


func test_un_masque_vert_ne_laisse_aucun_detail() -> void:
	_populator.set("terrain_texture", _mask(Color.GREEN))
	assert_int(_count(await _populate())).is_equal(0)


func test_hors_de_la_plage_de_hauteur_aucun_detail() -> void:
	_populator.set("rules_vertical_range", Vector2(5.0, 10.0))
	assert_int(_count(await _populate())).is_equal(0)
