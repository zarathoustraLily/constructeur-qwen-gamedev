extends GdUnitTestSuite
## La sélection : des identifiants sans doublon ; `changed` n'est émis que si elle change vraiment ; Maj+clic ajoute ou
## retire ; après une suppression, seuls les identifiants encore présents restent.

var _changes: int = 0


func _model() -> SelectionModel:
	_changes = 0
	var model: SelectionModel = SelectionModel.new()
	model.changed.connect(func() -> void: _changes += 1)
	return model


func test_les_doublons_et_les_identifiants_nuls_sont_retires() -> void:
	var model: SelectionModel = _model()
	model.replace([3, 3, 0, -1, 7])
	assert_array(model.ids()).is_equal([3, 7])


func test_changed_n_est_emis_que_si_la_selection_change() -> void:
	var model: SelectionModel = _model()
	model.replace([3])
	model.replace([3])
	model.add(3)
	assert_int(_changes).is_equal(1)


func test_maj_clic_ajoute_puis_retire() -> void:
	var model: SelectionModel = _model()
	model.toggle(4)
	assert_bool(model.contains(4)).is_true()
	model.toggle(4)
	assert_bool(model.is_empty()).is_true()


func test_seuls_les_identifiants_presents_restent() -> void:
	var model: SelectionModel = _model()
	model.replace([1, 2, 3])
	model.retain(PackedInt32Array([1, 3, 9]))
	assert_array(model.ids()).is_equal([1, 3])
