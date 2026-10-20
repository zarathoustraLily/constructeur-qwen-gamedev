extends GdUnitTestSuite
## Règles de l'éclair : il frappe sa cible et la suit quand elle bouge ; son flash s'allume ; il se supprime
## une fois éteint.

const LIGHTNING := preload("res://3_entities/effects/lightning/lightning_strike.tscn")

var _target: Node3D
var _strike: LightningStrike


func before_test() -> void:
	var camera: Camera3D = auto_free(Camera3D.new())
	add_child(camera)
	camera.position = Vector3(0.0, 2.0, 10.0)
	camera.make_current()
	_target = auto_free(Node3D.new())
	add_child(_target)
	_strike = LIGHTNING.instantiate() as LightningStrike
	_strike.target = _target
	add_child(_strike)


func test_il_frappe_sa_cible_et_la_suit() -> void:
	await get_tree().process_frame
	assert_vector(_strike.global_position).is_equal_approx(_strike.target_offset, Vector3.ONE * 0.001)
	_target.global_position = Vector3(5.0, 0.0, -3.0)
	await get_tree().process_frame
	assert_vector(_strike.global_position).is_equal_approx(Vector3(5.0, 0.0, -3.0) + _strike.target_offset,
		Vector3.ONE * 0.001)


func test_son_flash_s_allume() -> void:
	await get_tree().process_frame
	assert_float((_strike.get_node("Flash/Light") as OmniLight3D).light_energy).is_greater(0.0)


func test_il_se_supprime_une_fois_eteint() -> void:
	var seconds := maxf(_strike.arcs_duration, (_strike.get_node("Sparks") as GPUParticles3D).lifetime) + 0.3
	for _frame: int in int(seconds * 60.0):
		await get_tree().process_frame
	assert_bool(is_instance_valid(_strike)).is_false()
