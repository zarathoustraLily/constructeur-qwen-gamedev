extends GdUnitTestSuite
## Règles des traces du kart, avec un gestionnaire de traces témoin : elles suivent le kart ; chaque roue au
## sol imprime une marque pleine, une roue en l'air une marque de force nulle.

const KART := preload("res://3_entities/kart/kart.tscn")
const TracesTemoin := preload("res://7_tests/1_core/effects/tire_marks/traces_temoin.gd")

var _temoin: TireMarksManager
var _kart: Kart


func before_test() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = 8
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100.0, 1.0, 100.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child(auto_free(ground))
	_temoin = auto_free(TracesTemoin.new())
	add_child(_temoin)
	_kart = auto_free(KART.instantiate())
	_kart.input = null
	_kart.position = Vector3(0.0, 0.6, 0.0)
	add_child(_kart)


## Les quatre dernières traces demandées.
func _last_marks() -> Array[Array]:
	var traces: Array[Array] = _temoin.get("traces")
	return traces.slice(traces.size() - 4)


func test_les_traces_suivent_le_kart() -> void:
	for _frame: int in 30:
		await get_tree().process_frame
	var centre: Vector3 = _temoin.get("centre")
	assert_float(centre.distance_to(_kart.global_position)).is_less(0.5)


func test_une_roue_au_sol_imprime_une_marque_pleine() -> void:
	for _frame: int in 40:
		await get_tree().physics_frame
	await get_tree().process_frame
	var marks := _last_marks()
	for index: int in marks.size():
		var strength: float = marks[index][1]
		var radius: float = marks[index][2]
		assert_float(strength).is_equal(1.0)
		assert_float(radius).is_equal(9.0)


func test_une_roue_en_l_air_n_imprime_rien() -> void:
	_kart.global_position = Vector3(0.0, 20.0, 0.0)
	for _frame: int in 3:
		await get_tree().physics_frame
	await get_tree().process_frame
	var marks := _last_marks()
	for index: int in marks.size():
		var strength: float = marks[index][1]
		assert_float(strength).is_equal(0.0)
