extends GdUnitTestSuite
## Le cadrage : l'écran et la salle se convertissent dans les deux sens ; le zoom à la molette garde immobile le point
## sous le curseur et reste dans ses bornes ; cadrer une salle la montre entière, au milieu de la vue.

var _settings: EditorSettingsDef
var _transform: ViewTransform


func before_test() -> void:
	_settings = ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef
	_transform = ViewTransform.new()
	_transform.setup(_settings)
	_transform.origin = Vector2(100, 50)


func test_l_ecran_et_la_salle_se_convertissent_dans_les_deux_sens() -> void:
	var world: Vector3 = Vector3(3.5, 2.0, -1.25)
	var screen: Vector2 = _transform.world_to_screen(world)
	assert_vector(screen).is_equal(Vector2(100, 50) + Vector2(3.5, -1.25) * _settings.pixels_per_meter)
	assert_vector(_transform.screen_to_world(screen)).is_equal_approx(Vector3(3.5, 0, -1.25), Vector3.ONE * 0.0001)


func test_le_zoom_garde_le_point_sous_le_curseur() -> void:
	var cursor: Vector2 = Vector2(420, 310)
	var under: Vector3 = _transform.screen_to_world(cursor)
	_transform.zoom_at(cursor, _settings.zoom_step)
	assert_float(_transform.zoom).is_equal_approx(_settings.zoom_step, 0.0001)
	assert_vector(_transform.screen_to_world(cursor)).is_equal_approx(under, Vector3.ONE * 0.0001)


func test_le_zoom_reste_dans_ses_bornes() -> void:
	_transform.zoom_at(Vector2.ZERO, 1000.0)
	assert_float(_transform.zoom).is_equal(_settings.max_zoom)
	_transform.zoom_at(Vector2.ZERO, 0.00001)
	assert_float(_transform.zoom).is_equal(_settings.min_zoom)


func test_cadrer_montre_la_salle_entiere_au_milieu() -> void:
	var view: Vector2 = Vector2(800, 600)
	_transform.frame(Vector2(48, 32), view)
	var top_left: Vector2 = _transform.world_to_screen(Vector3.ZERO)
	var bottom_right: Vector2 = _transform.world_to_screen(Vector3(48, 0, 32))
	assert_bool(Rect2(Vector2.ZERO, view).encloses(Rect2(top_left, bottom_right - top_left))).is_true()
	assert_vector((top_left + bottom_right) / 2.0).is_equal_approx(view / 2.0, Vector2.ONE * 0.01)
