extends GdUnitTestSuite
## Règles de la chaleur d'arme : chaque tir la chauffe ; au maximum, elle surchauffe une fois et n'accepte plus rien ;
## elle refroidit après son délai, avec le temps qui reste ; surchauffée, elle se débloque à zéro, et le dit ; chaque
## changement s'annonce.

const SETTINGS := preload("res://5_data/hero/hero_gun_heat.tres")

var _heat: HeatComponent
var _overheats: int = 0
var _cooldowns: int = 0
var _changes: Array[float] = []


func before_test() -> void:
	_heat = auto_free(HeatComponent.new())
	_heat.settings = SETTINGS
	add_child(_heat)
	_overheats = 0
	_cooldowns = 0
	_changes.clear()
	_heat.overheated.connect(_on_overheated)
	_heat.cooled_down.connect(_on_cooled_down)


func _on_overheated() -> void:
	_overheats += 1


func _on_cooled_down() -> void:
	_cooldowns += 1


func _on_changed(current: float, _maximum: float) -> void:
	_changes.append(current)


func _fill() -> void:
	for _i: int in 10:
		_heat.add(SETTINGS.max_heat / 10.0)


func test_chaque_tir_la_chauffe() -> void:
	_heat.add(10.0)
	assert_float(_heat.heat).is_equal(10.0)
	assert_bool(_heat.is_overheated).is_false()


func test_au_maximum_elle_surchauffe_une_fois_et_n_accepte_plus_rien() -> void:
	_fill()
	assert_bool(_heat.is_overheated).is_true()
	assert_int(_overheats).is_equal(1)
	_heat.add(10.0)
	assert_float(_heat.heat).is_equal(SETTINGS.max_heat)
	assert_int(_overheats).is_equal(1)


func test_elle_refroidit_apres_son_delai() -> void:
	_heat.add(40.0)
	_heat.tick(SETTINGS.cool_delay - 0.05)
	assert_float(_heat.heat).is_equal(40.0)
	_heat.tick(0.55)
	assert_float(_heat.heat).is_equal_approx(40.0 - SETTINGS.cool_rate * 0.5, 0.001)


func test_surchauffee_elle_se_debloque_a_zero() -> void:
	_fill()
	_heat.tick(SETTINGS.cool_delay + 1.0)
	assert_bool(_heat.is_overheated).is_true()
	assert_int(_cooldowns).is_equal(0)
	_heat.tick(SETTINGS.max_heat / SETTINGS.cool_rate)
	assert_float(_heat.heat).is_equal(0.0)
	assert_bool(_heat.is_overheated).is_false()
	assert_int(_cooldowns).is_equal(1)


func test_chaque_changement_s_annonce() -> void:
	_heat.changed.connect(_on_changed)
	_heat.add(10.0)
	_heat.add(0.0)
	_heat.tick(SETTINGS.cool_delay + 0.1)
	assert_int(_changes.size()).is_equal(2)
	assert_float(_changes[0]).is_equal(10.0)
	assert_float(_changes[1]).is_equal_approx(10.0 - SETTINGS.cool_rate * 0.1, 0.001)
