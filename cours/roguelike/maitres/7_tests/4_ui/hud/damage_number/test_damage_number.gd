extends GdUnitTestSuite
## Règles d'un chiffre de dégâts : il écrit les dégâts avec une décimale ; il se place à l'écran au-dessus de son
## point du monde, vu par la caméra ; son animation le libère au bout d'une seconde.

const NUMBER := preload("res://4_ui/hud/damage_number/damage_number.tscn")


func before_test() -> void:
	var camera: Camera3D = auto_free(Camera3D.new())
	add_child(camera)
	camera.position = Vector3(0.0, 2.0, 8.0)
	camera.make_current()


func test_il_ecrit_les_degats_avec_une_decimale() -> void:
	var number: DamageNumber = auto_free(NUMBER.instantiate())
	add_child(number)
	number.set_damage_text(14.0)
	assert_str(number.label.text).is_equal("14.0")


func test_il_se_place_au_dessus_de_son_point_du_monde() -> void:
	var number: DamageNumber = auto_free(NUMBER.instantiate())
	add_child(number)
	number.target_position = Vector3(1.0, 1.0, 0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	var expected := get_viewport().get_camera_3d().unproject_position(number.target_position)
	assert_vector(number.position).is_equal_approx(expected, Vector2.ONE * 0.5)


func test_son_animation_le_libere_au_bout_d_une_seconde() -> void:
	var number := NUMBER.instantiate() as DamageNumber
	add_child(number)
	for _frame: int in 70:
		await get_tree().process_frame
	assert_bool(is_instance_valid(number)).is_false()
