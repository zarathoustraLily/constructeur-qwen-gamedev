extends GdUnitTestSuite
## Règles de la scène du feu sur la carte : la texture montrée est toujours celle de la température du pas courant ; la source
## nourrit le feu, et la chaleur s'y voit sans repasser par le processeur ; un glissé de la souris pousse le fluide ; quitter la
## scène rend tout à la carte.

const SCENE := preload("res://2_sequence/gpu_fire.tscn")


func _fire() -> Control:
	var fire: Control = SCENE.instantiate()
	add_child(fire)
	return fire


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func _shown(fire: Control) -> Texture2DRD:
	return (fire.get_node("View") as TextureRect).texture as Texture2DRD


func test_la_texture_montree_est_celle_du_pas_courant() -> void:
	var fire: Control = auto_free(_fire())
	await _frames(3)
	var solver: GpuSolver = fire.get("_solver")
	assert_bool(_shown(fire).texture_rd_rid == solver.temperature).is_true()
	await _frames(1)
	assert_bool(_shown(fire).texture_rd_rid == solver.temperature).is_true()


func test_la_chaleur_se_voit_la_ou_la_source_nourrit_le_feu() -> void:
	var fire: Control = auto_free(_fire())
	await _frames(12)
	var image: Image = _shown(fire).get_image()
	var settings: FluidSettings = fire.get("settings")
	assert_int(image.get_width()).is_equal(settings.width)
	assert_float(image.get_pixel(int(settings.width * 0.5), int(settings.height * 0.9)).r).is_greater(0.0)
	assert_float(image.get_pixel(4, 4).r).is_equal(0.0)


func test_un_glisse_de_la_souris_pousse_le_fluide() -> void:
	var fire: Control = auto_free(_fire())
	await _frames(1)
	var geste: InputEventMouseMotion = InputEventMouseMotion.new()
	geste.button_mask = MOUSE_BUTTON_MASK_LEFT
	geste.position = (fire.get_node("View") as TextureRect).size * 0.5
	geste.relative = Vector2(30.0, 0.0)
	fire.call("_unhandled_input", geste)
	var solver: GpuSolver = fire.get("_solver")
	var settings: FluidSettings = fire.get("settings")
	var vitesse: FluidField = FluidField.new(settings.width, settings.height)
	solver.device.download(solver.u, vitesse)
	assert_float(vitesse.peak()).is_greater(0.0)


func test_quitter_la_scene_rend_tout_a_la_carte() -> void:
	var fire: Control = _fire()
	await _frames(1)
	var device: ComputeDevice = fire.get("_device")
	fire.free()
	assert_object(device.rd).is_null()
