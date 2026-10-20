extends GdUnitTestSuite
## Règles de la pluie dessinée : elle tombe quand on lui donne une force, pas sans ; sous l'averse, le soleil
## faiblit et le brouillard s'épaissit, et tout revient comme avant quand elle part ; elle suit la caméra, au-
## dessus d'elle.

const RAIN := preload("res://3_entities/effects/rain/rain.tscn")

var _sun: DirectionalLight3D
var _environment: WorldEnvironment
var _camera: Camera3D
var _rain: RainView


func before_test() -> void:
	_sun = auto_free(DirectionalLight3D.new())
	_sun.light_energy = 2.0
	add_child(_sun)
	_environment = auto_free(WorldEnvironment.new())
	_environment.environment = Environment.new()
	_environment.environment.fog_density = 0.01
	add_child(_environment)
	_camera = auto_free(Camera3D.new())
	add_child(_camera)
	_camera.make_current()
	_rain = RAIN.instantiate() as RainView
	_rain.sun = _sun
	_rain.environment = _environment
	add_child(_rain)


func after_test() -> void:
	if is_instance_valid(_rain):
		_rain.free()


func _drops() -> GPUParticles3D:
	return _rain.get_node("Drops") as GPUParticles3D


func test_sans_force_il_ne_pleut_pas() -> void:
	_rain.intensity = 0.0
	await get_tree().process_frame
	assert_bool(_drops().emitting).is_false()


func test_sous_l_averse_le_soleil_faiblit_et_le_brouillard_s_epaissit() -> void:
	_rain.intensity = 1.0
	await get_tree().process_frame
	assert_bool(_drops().emitting).is_true()
	assert_float(_sun.light_energy).is_equal_approx(2.0 * (1.0 - _rain.sun_dim), 0.0001)
	assert_float(_environment.environment.fog_density).is_equal_approx(0.01 + _rain.extra_fog_density, 0.0001)


func test_quand_la_pluie_part_tout_revient() -> void:
	_rain.intensity = 1.0
	await get_tree().process_frame
	_rain.free()
	assert_float(_sun.light_energy).is_equal(2.0)
	assert_float(_environment.environment.fog_density).is_equal_approx(0.01, 0.0001)


func test_la_pluie_tombe_au_dessus_de_la_camera() -> void:
	_camera.global_position = Vector3(10.0, 2.0, -4.0)
	_rain.intensity = 1.0
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(_rain.global_position.y).is_equal_approx(2.0 + _rain.height_above_camera, 0.01)
	assert_float(Vector2(_rain.global_position.x, _rain.global_position.z).distance_to(Vector2(10.0, -4.0))).is_less(5.0)
