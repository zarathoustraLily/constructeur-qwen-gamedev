extends GdUnitTestSuite
## Les gestes : chacun fait un seul pas d'annulation ; déplacer s'aimante à la grille ; tourner fait le tour du cadran,
## et un groupe tourne autour de son centre ; l'échelle reste dans ses bornes, et un groupe s'écarte de son centre ;
## dupliquer décale et garde l'attache au double du parent ; la profondeur avance, recule, passe devant ou derrière tout
## le calque ; un asset ajouté va dans son calque par défaut, devant les autres ; un calque ou un asset inconnu est refusé.

var _document: RoomDocument
var _actions: EditorActions
var _settings: EditorSettingsDef


func before_test() -> void:
	_document = RoomDocument.new()
	_document.open(RoomStore.new().load_room("res://5_data/salles/pont.tres"))
	_settings = ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef
	_actions = EditorActions.new()
	_actions.setup(_document, ResourceLoader.load("res://5_data/catalogue/catalogue.tres") as AssetCatalogDef,
			_settings)


func _obstacles(count: int) -> Array[int]:
	var found: Array[int] = []
	for thing_id: int in _document.ids():
		if _document.value(thing_id, &"layer") == "obstacles" and found.size() < count:
			found.append(thing_id)
	return found


func _steps_to_undo() -> int:
	var steps: int = 0
	while _document.undo():
		steps += 1
	return steps


func test_les_reglages_d_exemple_sont_valides() -> void:
	assert_array(_settings.validate()).is_empty()


func test_deplacer_un_groupe_fait_un_seul_pas() -> void:
	var ids: Array[int] = _obstacles(3)
	var before_position: Vector3 = _document.value(ids[2], &"position")
	assert_bool(_actions.move(ids, Vector3(1, 0, -2))).is_true()
	assert_vector(_document.value(ids[2], &"position")).is_equal_approx(before_position + Vector3(1, 0, -2),
			Vector3.ONE * 0.001)
	assert_int(_steps_to_undo()).is_equal(1)


func test_deplacer_s_aimante_a_la_grille() -> void:
	var ids: Array[int] = _obstacles(1)
	_actions.move(ids, Vector3(0.13, 0, 0.61), true)
	var position: Vector3 = _document.value(ids[0], &"position")
	assert_float(fposmod(position.x, _settings.snap_m)).is_equal_approx(0.0, 0.001)
	assert_float(fposmod(position.z, _settings.snap_m)).is_equal_approx(0.0, 0.001)


func test_tourner_fait_le_tour_du_cadran() -> void:
	var ids: Array[int] = _obstacles(1)
	_document.set_value(ids[0], &"rotation", 350.0)
	assert_bool(_actions.rotate(ids, 20.0)).is_true()
	assert_float(_document.value(ids[0], &"rotation")).is_equal_approx(10.0, 0.001)


func test_un_groupe_tourne_autour_de_son_centre() -> void:
	var ids: Array[int] = _obstacles(2)
	var center: Vector3 = _actions.center_of(ids)
	var distance: float = Vector2(center.x, center.z).distance_to(Vector2(
			Vector3(_document.value(ids[0], &"position")).x, Vector3(_document.value(ids[0], &"position")).z))
	_actions.rotate(ids, 90.0)
	var moved: Vector3 = _document.value(ids[0], &"position")
	assert_vector(_actions.center_of(ids)).is_equal_approx(center, Vector3.ONE * 0.001)
	assert_float(Vector2(center.x, center.z).distance_to(Vector2(moved.x, moved.z))).is_equal_approx(distance, 0.001)


func test_l_echelle_reste_dans_ses_bornes() -> void:
	var ids: Array[int] = _obstacles(1)
	_actions.scale_by(ids, 1000.0)
	assert_float(_document.value(ids[0], &"scale")).is_equal_approx(_settings.max_scale, 0.001)
	_actions.scale_by(ids, 0.00001)
	assert_float(_document.value(ids[0], &"scale")).is_equal_approx(_settings.min_scale, 0.001)


func test_dupliquer_decale_et_garde_l_attache() -> void:
	var parent: int = _obstacles(1)[0]
	var child: int = _document.add_thing({&"asset": "lampe", &"layer": "avant_plan", &"parent": parent})
	var copies: Array[int] = _actions.duplicate([parent, child])
	assert_int(copies.size()).is_equal(2)
	assert_int(_document.value(copies[1], &"parent")).is_equal(copies[0])
	assert_vector(_document.value(copies[0], &"position")).is_equal_approx(
			Vector3(_document.value(parent, &"position")) + _settings.duplicate_offset_m, Vector3.ONE * 0.001)
	assert_bool(_document.undo()).is_true()
	assert_int(_document.ids().find(copies[0])).is_equal(-1)


func test_la_profondeur_avance_recule_et_passe_devant_tout() -> void:
	var ids: Array[int] = _obstacles(2)
	_actions.shift_depth([ids[0]], 1)
	assert_int(_document.value(ids[0], &"sort")).is_equal(1)
	_actions.shift_depth([ids[0]], -2)
	assert_int(_document.value(ids[0], &"sort")).is_equal(-1)
	_actions.to_extreme_depth([ids[1]], true)
	var front: int = _document.value(ids[1], &"sort")
	for other: int in _document.ids():
		if other != ids[1] and _document.value(other, &"layer") == "obstacles":
			assert_int(_document.value(other, &"sort")).is_less(front)


func test_un_asset_ajoute_va_dans_son_calque_devant_les_autres() -> void:
	var created: int = _actions.add_asset(&"fut_carburant", Vector3(4, 0, 4))
	assert_int(created).is_greater(0)
	assert_str(_document.value(created, &"layer")).is_equal("obstacles")
	assert_int(_steps_to_undo()).is_equal(1)


func test_un_calque_ou_un_asset_inconnu_est_refuse() -> void:
	var ids: Array[int] = _obstacles(1)
	assert_bool(_actions.set_layer(ids, "plafond")).is_false()
	assert_array(_actions.errors).contains(["chose %d : calque inconnu plafond" % ids[0]])
	assert_int(_actions.add_asset(&"licorne", Vector3.ZERO)).is_equal(0)
	assert_array(_actions.errors).is_equal(["asset licorne : absent du catalogue"])
