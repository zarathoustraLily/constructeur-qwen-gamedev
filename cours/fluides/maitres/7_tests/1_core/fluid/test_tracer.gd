extends GdUnitTestSuite
## Règles d'une particule : sans courant, elle ne bouge pas ; dans un courant uniforme, elle avance de vitesse fois temps ; entre deux cases,
## le courant se mélange ; dans un tourbillon, lire le courant à mi-chemin la garde sur son cercle, là où une ligne droite la fait sortir.

const SIZE := 32
const CENTER := Vector2(16.0, 16.0)


func _uniform(value: float) -> FluidField:
	var field: FluidField = FluidField.new(SIZE, SIZE)
	field.fill(value)
	return field


## Le tourbillon autour de `CENTER` : une rotation d'un radian par seconde. Un champ linéaire : le mélange bilinéaire le lit exactement.
func _spin_u() -> FluidField:
	var field: FluidField = FluidField.new(SIZE, SIZE)
	for y: int in SIZE:
		for x: int in SIZE:
			field.put(x, y, -(y - CENTER.y))
	return field


func _spin_v() -> FluidField:
	var field: FluidField = FluidField.new(SIZE, SIZE)
	for y: int in SIZE:
		for x: int in SIZE:
			field.put(x, y, x - CENTER.x)
	return field


func test_sans_courant_elle_ne_bouge_pas() -> void:
	var point: Vector2 = Tracer.moved(Vector2(3.5, 4.5), _uniform(0.0), _uniform(0.0), 0.5)
	assert_vector(point).is_equal(Vector2(3.5, 4.5))


func test_dans_un_courant_uniforme_elle_avance_de_vitesse_fois_temps() -> void:
	var point: Vector2 = Tracer.moved(Vector2(5.0, 5.0), _uniform(4.0), _uniform(-2.0), 0.5)
	assert_vector(point).is_equal_approx(Vector2(7.0, 4.0), Vector2(0.0001, 0.0001))


func test_entre_deux_cases_le_courant_se_melange() -> void:
	var u: FluidField = _uniform(0.0)
	u.put(6, 5, 2.0)
	var courant: Vector2 = Tracer.current_at(Vector2(5.5, 5.0), u, _uniform(0.0))
	assert_float(courant.x).is_equal_approx(1.0, 0.0001)


func test_lire_a_mi_chemin_garde_la_particule_sur_son_cercle() -> void:
	var u: FluidField = _spin_u()
	var v: FluidField = _spin_v()
	var point: Vector2 = CENTER + Vector2(8.0, 0.0)
	for _pas: int in 60:
		point = Tracer.moved(point, u, v, 0.05)
	assert_float(point.distance_to(CENTER)).is_equal_approx(8.0, 0.05)


func test_une_ligne_droite_sort_du_virage() -> void:
	var u: FluidField = _spin_u()
	var v: FluidField = _spin_v()
	var point: Vector2 = CENTER + Vector2(8.0, 0.0)
	for _pas: int in 60:
		point += Tracer.current_at(point, u, v) * 0.05
	assert_float(point.distance_to(CENTER)).is_greater(8.5)
