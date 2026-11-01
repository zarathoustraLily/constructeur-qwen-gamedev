extends GdUnitTestSuite
## Règles de la crue à l'écran : la texture montrée est la profondeur du pas courant ; la source donne de l'eau, et l'eau descend ; un glissé
## de la souris verse de l'eau là où il passe ; le relief descend vers le bas de l'image ; quitter la scène rend tout à la carte.

const SCENE := preload("res://2_sequence/gpu_flood.tscn")


func _flood() -> Control:
	var flood: Control = SCENE.instantiate()
	add_child(flood)
	return flood


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func _depth(flood: Control) -> FluidField:
	var eau: GpuFlood = flood.get("_flood")
	var device: ComputeDevice = flood.get("_device")
	return GridCheck.read(device, eau.depth, eau.settings.width, eau.settings.height)


func test_la_texture_montree_est_la_profondeur_du_pas_courant() -> void:
	var flood: Control = auto_free(_flood())
	await _frames(3)
	var texture: Texture2DRD = flood.get("_texture")
	var eau: GpuFlood = flood.get("_flood")
	assert_bool(texture.texture_rd_rid == eau.depth).is_true()
	await _frames(1)
	assert_bool(texture.texture_rd_rid == eau.depth).is_true()


func test_la_source_donne_de_l_eau_et_elle_descend() -> void:
	var flood: Control = auto_free(_flood())
	await _frames(2)
	var tot: FluidField = _depth(flood)
	await _frames(40)
	var tard: FluidField = _depth(flood)
	assert_float(tard.total()).is_greater(tot.total())
	assert_float(tard.at(128, 60)).is_greater(tot.at(128, 60))


func test_un_glisse_de_la_souris_verse_de_l_eau_la_ou_il_passe() -> void:
	var flood: Control = auto_free(_flood())
	await _frames(1)
	var geste: InputEventMouseMotion = InputEventMouseMotion.new()
	geste.button_mask = MOUSE_BUTTON_MASK_LEFT
	geste.position = (flood.get_node("View") as TextureRect).size * Vector2(0.25, 0.75)
	flood.call("_unhandled_input", geste)
	assert_float(_depth(flood).at(64, 192)).is_greater(0.5)


func test_sans_bouton_un_mouvement_ne_verse_rien() -> void:
	var flood: Control = auto_free(_flood())
	await _frames(1)
	var geste: InputEventMouseMotion = InputEventMouseMotion.new()
	geste.position = (flood.get_node("View") as TextureRect).size * Vector2(0.25, 0.75)
	flood.call("_unhandled_input", geste)
	assert_float(_depth(flood).at(64, 192)).is_equal(0.0)


func test_le_relief_descend_vers_le_bas_de_l_image() -> void:
	var sol: FluidField = load("res://2_sequence/gpu_flood.gd").hills(64, 64)
	assert_float(sol.at(32, 2)).is_greater(sol.at(32, 61))


func test_quitter_la_scene_rend_tout_a_la_carte() -> void:
	var flood: Control = _flood()
	await _frames(1)
	var device: ComputeDevice = flood.get("_device")
	flood.free()
	assert_object(device.rd).is_null()
