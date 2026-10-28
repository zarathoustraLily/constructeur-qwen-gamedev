extends GdUnitTestSuite
## Règles des fioles : remplies, elles sont toutes là ; chaque fiole bue en retire une ; sans fiole, rien ne se boit ;
## chaque changement s'annonce.

var _flasks: FlaskComponent
var _changes: Array[Vector2i] = []


func before_test() -> void:
	_flasks = auto_free(FlaskComponent.new())
	add_child(_flasks)
	_changes.clear()
	_flasks.changed.connect(_on_changed)


func _on_changed(charges: int, maximum: int) -> void:
	_changes.append(Vector2i(charges, maximum))


func test_remplies_elles_sont_toutes_la() -> void:
	_flasks.fill(3)
	assert_int(_flasks.charges).is_equal(3)
	assert_int(_flasks.max_charges).is_equal(3)
	assert_bool(_flasks.has_charge()).is_true()


func test_chaque_fiole_bue_en_retire_une_jusqu_a_zero() -> void:
	_flasks.fill(2)
	assert_bool(_flasks.use()).is_true()
	assert_bool(_flasks.use()).is_true()
	assert_bool(_flasks.has_charge()).is_false()
	assert_bool(_flasks.use()).is_false()
	assert_int(_flasks.charges).is_equal(0)


func test_chaque_changement_s_annonce() -> void:
	_flasks.fill(2)
	_flasks.use()
	assert_array(_changes).is_equal([Vector2i(2, 2), Vector2i(1, 2)])
