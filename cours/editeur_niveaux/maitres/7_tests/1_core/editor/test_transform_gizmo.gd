extends GdUnitTestSuite
## Le cadre bleu : ses poignées sont aux coins et au-dessus du milieu ; la souris trouve la poignée, l'intérieur ou
## rien ; une poignée d'angle tirée deux fois plus loin du centre double l'échelle ; la poignée ronde amenée d'en haut à
## droite du centre a tourné d'un quart de tour ; sans sélection, rien n'est sous la souris.

var _settings: EditorSettingsDef
var _gizmo: TransformGizmo


func before_test() -> void:
	_settings = ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef
	_gizmo = TransformGizmo.new()
	_gizmo.setup(_settings)
	_gizmo.box = Rect2(100, 100, 200, 100)


func test_les_poignees_sont_aux_coins_et_au_dessus_du_milieu() -> void:
	assert_vector(_gizmo.point_of(TransformGizmo.Handle.TOP_LEFT)).is_equal(Vector2(100, 100))
	assert_vector(_gizmo.point_of(TransformGizmo.Handle.BOTTOM_RIGHT)).is_equal(Vector2(300, 200))
	assert_vector(_gizmo.point_of(TransformGizmo.Handle.ROTATE)).is_equal(
			Vector2(200, 100 - _settings.rotate_handle_offset_px))


func test_la_souris_trouve_la_poignee_l_interieur_ou_rien() -> void:
	assert_int(_gizmo.hit_test(Vector2(301, 199))).is_equal(TransformGizmo.Handle.BOTTOM_RIGHT)
	assert_int(_gizmo.hit_test(_gizmo.point_of(TransformGizmo.Handle.ROTATE))).is_equal(TransformGizmo.Handle.ROTATE)
	assert_int(_gizmo.hit_test(Vector2(180, 150))).is_equal(TransformGizmo.Handle.BODY)
	assert_int(_gizmo.hit_test(Vector2(500, 500))).is_equal(TransformGizmo.Handle.NONE)


func test_une_poignee_d_angle_deux_fois_plus_loin_double_l_echelle() -> void:
	_gizmo.begin(TransformGizmo.Handle.BOTTOM_RIGHT, Vector2(300, 200))
	assert_float(_gizmo.factor_to(Vector2(400, 250))).is_equal_approx(2.0, 0.0001)


func test_la_poignee_ronde_tourne_d_un_quart_de_tour() -> void:
	var center: Vector2 = _gizmo.box.get_center()
	_gizmo.begin(TransformGizmo.Handle.ROTATE, center + Vector2(0, -50))
	assert_float(_gizmo.angle_to(center + Vector2(50, 0))).is_equal_approx(90.0, 0.0001)


func test_sans_selection_rien_n_est_sous_la_souris() -> void:
	_gizmo.box = Rect2()
	assert_int(_gizmo.hit_test(Vector2(0, 0))).is_equal(TransformGizmo.Handle.NONE)
