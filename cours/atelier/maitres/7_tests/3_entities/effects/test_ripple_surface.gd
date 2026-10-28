extends GdUnitTestSuite
## Règles de la surface d'eau : plate au repos ; un impact lance une onde qui la soulève près du point d'impact ; son
## maillage suit l'onde ; loin du front, elle reste plate.

const SETTINGS := preload("res://5_data/vfx/ripple.tres")


func _surface() -> RippleSurface:
	var surface: RippleSurface = auto_free(RippleSurface.new())
	surface.settings = SETTINGS
	add_child(surface)
	return surface


func _max_height(surface: RippleSurface) -> float:
	var vertices: PackedVector3Array = surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var highest: float = 0.0
	for vertex: Vector3 in vertices:
		highest = maxf(highest, absf(vertex.y))
	return highest


func test_plate_au_repos() -> void:
	var surface: RippleSurface = _surface()
	surface.advance(0.5)
	assert_float(_max_height(surface)).is_equal(0.0)
	assert_float(surface.height_at(Vector2.ZERO)).is_equal(0.0)


func test_un_impact_souleve_l_eau_et_le_maillage_suit() -> void:
	var surface: RippleSurface = _surface()
	surface.drop(Vector2(1.0, -1.0))
	surface.advance(0.3)
	assert_float(_max_height(surface)).is_greater(0.01)
	var near: float = absf(surface.height_at(Vector2(1.0, -1.0) + Vector2(SETTINGS.speed * 0.3 - SETTINGS.wavelength * 0.25, 0.0)))
	assert_float(near).is_greater(0.0)


func test_loin_du_front_l_eau_reste_plate() -> void:
	var surface: RippleSurface = _surface()
	surface.drop(Vector2(-4.0, -4.0))
	surface.advance(0.2)
	assert_float(surface.height_at(Vector2(4.0, 4.0))).is_equal(0.0)
