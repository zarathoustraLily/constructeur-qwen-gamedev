extends GdUnitTestSuite
## Règles de l'eau à l'écran : la texture montrée est la surface du pas courant ; un point du plan tombe sur sa case ; un clic pose une
## goutte là où il tombe ; il pleut à la cadence demandée ; quitter la scène rend tout à la carte.

const SCENE := preload("res://2_sequence/gpu_waves.tscn")
const PIXELS := 64


func _scene(rain: float) -> Node3D:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(PIXELS, PIXELS)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	auto_free(viewport)
	var water: Node3D = SCENE.instantiate()
	water.set("drop_every", rain)
	viewport.add_child(water)
	return water


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func _surface(water: Node3D) -> FluidField:
	var waves: GpuWaves = water.get("_waves")
	var device: ComputeDevice = water.get("_device")
	return GridCheck.read(device, waves.surface, waves.settings.width, waves.settings.height)


func test_la_texture_montree_est_la_surface_du_pas_courant() -> void:
	var water: Node3D = _scene(0.0)
	await _frames(3)
	var texture: Texture2DRD = water.get("_texture")
	var waves: GpuWaves = water.get("_waves")
	assert_bool(texture.texture_rd_rid == waves.surface).is_true()
	await _frames(1)
	assert_bool(texture.texture_rd_rid == waves.surface).is_true()


func test_un_point_du_plan_tombe_sur_sa_case() -> void:
	var water: Node3D = _scene(0.0)
	var centre: Vector2 = water.call("cell_of", Vector3.ZERO)
	assert_vector(centre).is_equal_approx(Vector2(128.0, 128.0), Vector2(0.001, 0.001))
	var coin: Vector2 = water.call("cell_of", Vector3(-4.0, 0.0, 4.0))
	assert_vector(coin).is_equal_approx(Vector2(0.0, 256.0), Vector2(0.001, 0.001))


func test_un_clic_pose_une_goutte_la_ou_il_tombe() -> void:
	var water: Node3D = _scene(0.0)
	await _frames(1)
	var clic: InputEventMouseButton = InputEventMouseButton.new()
	clic.pressed = true
	clic.position = Vector2(PIXELS * 0.5, PIXELS * 0.5)
	water.call("_unhandled_input", clic)
	var surface: FluidField = _surface(water)
	assert_float(surface.at(128, 128)).is_less(-1.0)
	assert_float(surface.at(20, 20)).is_equal(0.0)


func test_relacher_le_clic_ne_pose_rien() -> void:
	var water: Node3D = _scene(0.0)
	await _frames(1)
	var clic: InputEventMouseButton = InputEventMouseButton.new()
	clic.pressed = false
	clic.position = Vector2(PIXELS * 0.5, PIXELS * 0.5)
	water.call("_unhandled_input", clic)
	assert_float(GridCheck.mean_size(_surface(water))).is_equal(0.0)


func test_il_pleut_a_la_cadence_demandee() -> void:
	var water: Node3D = _scene(0.05)
	await _frames(2)
	assert_float(GridCheck.mean_size(_surface(water))).is_greater(0.0)


func test_sans_pluie_l_eau_reste_plate() -> void:
	var water: Node3D = _scene(0.0)
	await _frames(4)
	assert_float(GridCheck.mean_size(_surface(water))).is_equal(0.0)


func test_quitter_la_scene_rend_tout_a_la_carte() -> void:
	var water: Node3D = _scene(0.0)
	await _frames(1)
	var device: ComputeDevice = water.get("_device")
	water.free()
	assert_object(device.rd).is_null()
