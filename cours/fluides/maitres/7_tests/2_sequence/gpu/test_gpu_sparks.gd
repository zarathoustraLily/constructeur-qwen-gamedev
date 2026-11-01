extends GdUnitTestSuite
## Règles des étincelles à l'écran : une particule se dessine à sa place, sans repasser par le processeur ; la scène montre la température du
## pas courant ; les étincelles bougent et leur tampon suit ; quitter la scène rend tout à la carte.

const SCENE := preload("res://2_sequence/gpu_sparks.tscn")
const PIXELS := 64

var _device: ComputeDevice


func after_test() -> void:
	if _device != null:
		_device.release()
		_device = null


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


## L'image du viewport. Une scène immobile ne redessine pas d'elle-même : on force le dessin.
func _image(viewport: SubViewport) -> Image:
	for _i: int in 3:
		await get_tree().process_frame
		RenderingServer.force_draw(false)
	return viewport.get_texture().get_image()


func test_une_particule_se_dessine_a_sa_place() -> void:
	_device = ComputeDevice.shared()
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(PIXELS, PIXELS)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	auto_free(viewport)
	var plaque: QuadMesh = QuadMesh.new()
	plaque.size = Vector2(6.0, 6.0)
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.mesh = plaque
	multimesh.custom_aabb = AABB(Vector3.ZERO, Vector3(PIXELS, PIXELS, 1.0))
	multimesh.instance_count = 1
	var instance: MultiMeshInstance2D = MultiMeshInstance2D.new()
	instance.multimesh = multimesh
	viewport.add_child(instance)
	var tracers: GpuTracers = GpuTracers.new(_device, PackedVector2Array([Vector2(20.0, 44.0)]), PIXELS, PIXELS)
	tracers.write_instances(RenderingServer.multimesh_get_buffer_rd_rid(multimesh.get_rid()))
	var image: Image = await _image(viewport)
	assert_float(image.get_pixel(20, 44).a).is_greater(0.9)
	assert_float(image.get_pixel(44, 20).a).is_equal(0.0)


func test_la_texture_montree_est_la_temperature_du_pas_courant() -> void:
	var scene: Control = auto_free(SCENE.instantiate())
	add_child(scene)
	await _frames(3)
	var texture: Texture2DRD = scene.get("_texture")
	var solver: GpuSolver = scene.get("_solver")
	assert_bool(texture.texture_rd_rid == solver.temperature).is_true()


func test_les_etincelles_bougent() -> void:
	var scene: Control = auto_free(SCENE.instantiate())
	scene.set("spark_count", 200)
	add_child(scene)
	await _frames(1)
	var device: ComputeDevice = scene.get("_device")
	var tracers: GpuTracers = scene.get("_tracers")
	var avant: PackedFloat32Array = device.read_buffer(tracers.positions)
	await _frames(20)
	var apres: PackedFloat32Array = device.read_buffer(tracers.positions)
	assert_bool(avant == apres).is_false()


func test_toutes_les_etincelles_partent_de_la_source() -> void:
	var scene: Control = auto_free(SCENE.instantiate())
	scene.set("spark_count", 50)
	add_child(scene)
	await _frames(1)
	var settings: FluidSettings = scene.get("settings")
	for depart: Vector2 in scene.call("_spark_starts"):
		assert_float(depart.y).is_greater(settings.height * 0.5)


func test_le_tampon_du_moteur_recoit_les_etincelles() -> void:
	var scene: Control = auto_free(SCENE.instantiate())
	scene.set("spark_count", 10)
	add_child(scene)
	await _frames(2)
	var device: ComputeDevice = scene.get("_device")
	var tracers: GpuTracers = scene.get("_tracers")
	var positions: PackedFloat32Array = device.read_buffer(tracers.positions)
	var tampon: PackedFloat32Array = device.read_buffer(scene.get("_instances"))
	assert_float(tampon[3]).is_equal_approx(positions[0], 0.001)
	assert_float(tampon[7]).is_equal_approx(positions[1], 0.001)


func test_quitter_la_scene_rend_tout_a_la_carte() -> void:
	var scene: Control = SCENE.instantiate()
	scene.set("spark_count", 10)
	add_child(scene)
	await _frames(1)
	var device: ComputeDevice = scene.get("_device")
	scene.free()
	assert_object(device.rd).is_null()
