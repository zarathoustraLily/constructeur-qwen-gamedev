extends GdUnitTestSuite
## Règles du tremblement : le traumatisme s'additionne jusqu'à un ; il retombe avec le temps ; la force est son
## carré ; sans traumatisme, aucun décalage ; le décalage ne dépasse jamais le maximum ; le même instant donne le
## même décalage (un bruit, pas un hasard).

const SETTINGS := preload("res://5_data/vfx/vfx.tres")


func _shake() -> CameraShake:
	var camera: Camera3D = auto_free(Camera3D.new())
	add_child(camera)
	var shake: CameraShake = auto_free(CameraShake.new())
	shake.camera = camera
	shake.settings = SETTINGS
	add_child(shake)
	return shake


func test_le_traumatisme_s_additionne_jusqu_a_un() -> void:
	var shake: CameraShake = _shake()
	shake.add_trauma(0.4)
	shake.add_trauma(0.4)
	assert_float(shake.trauma).is_equal_approx(0.8, 0.0001)
	shake.add_trauma(0.9)
	assert_float(shake.trauma).is_equal(1.0)


func test_il_retombe_avec_le_temps() -> void:
	var shake: CameraShake = _shake()
	shake.add_trauma(1.0)
	shake.update(0.2)
	assert_float(shake.trauma).is_equal_approx(1.0 - SETTINGS.shake_decay * 0.2, 0.0001)
	shake.update(10.0)
	assert_float(shake.trauma).is_equal(0.0)


func test_la_force_est_le_carre_du_traumatisme() -> void:
	var shake: CameraShake = _shake()
	shake.add_trauma(0.5)
	assert_float(shake.intensity()).is_equal_approx(0.25, 0.0001)


func test_sans_traumatisme_aucun_decalage() -> void:
	var shake: CameraShake = _shake()
	shake.update(0.1)
	assert_vector(shake.offset(1.234)).is_equal(Vector2.ZERO)
	assert_float(shake.camera.h_offset).is_equal(0.0)


func test_le_decalage_ne_depasse_jamais_le_maximum() -> void:
	var shake: CameraShake = _shake()
	shake.add_trauma(1.0)
	for i: int in 200:
		var shift: Vector2 = shake.offset(i * 0.013)
		assert_float(absf(shift.x)).is_less_equal(SETTINGS.shake_max_offset)
		assert_float(absf(shift.y)).is_less_equal(SETTINGS.shake_max_offset)


func test_le_meme_instant_donne_le_meme_decalage() -> void:
	var shake: CameraShake = _shake()
	shake.add_trauma(1.0)
	assert_vector(shake.offset(0.5)).is_equal(shake.offset(0.5))
	assert_bool(shake.offset(0.5).is_equal_approx(shake.offset(0.9))).is_false()
