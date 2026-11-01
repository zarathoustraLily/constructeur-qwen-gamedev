extends GdUnitTestSuite
## Règles de la projection : un courant uniforme n'a pas de divergence ; une source en a ; la pression efface presque toute la
## divergence ; surrelaxée, elle y arrive en moins de passes ; un courant déjà sans divergence ne change pas.
#@ 6+
## Un mur garde une vitesse nulle, et le courant le contourne.
#@ all


## La racine de la moyenne des carrés d'un champ, loin de ses bords.
func _efficace(champ: FluidField) -> float:
	var somme: float = 0.0
	var cases: int = 0
	for y: int in range(4, champ.height - 4):
		for x: int in range(4, champ.width - 4):
			somme += champ.at(x, y) * champ.at(x, y)
			cases += 1
	return sqrt(somme / cases)


#@ 4-5
func _divergence(sortie: FluidField, u: FluidField, v: FluidField) -> void:
	FluidProjection.divergence(sortie, u, v)


func _pression(pression: FluidField, divergence: FluidField, passes: int, relaxation: float) -> void:
	FluidProjection.solve_pressure(pression, divergence, passes, relaxation)


func _pente(u: FluidField, v: FluidField, pression: FluidField) -> void:
	FluidProjection.subtract_gradient(u, v, pression)
#@ 6+
func _divergence(sortie: FluidField, u: FluidField, v: FluidField) -> void:
	FluidProjection.divergence(sortie, u, v, ObstacleMask.new(u.width, u.height))


func _pression(pression: FluidField, divergence: FluidField, passes: int, relaxation: float) -> void:
	FluidProjection.solve_pressure(pression, divergence, ObstacleMask.new(pression.width, pression.height), passes, relaxation)


func _pente(u: FluidField, v: FluidField, pression: FluidField) -> void:
	FluidProjection.subtract_gradient(u, v, pression, ObstacleMask.new(u.width, u.height))
#@ all


## Un courant lisse qui jaillit du centre : il a beaucoup de divergence.
func _source(taille: int) -> Array[FluidField]:
	var u: FluidField = FluidField.new(taille, taille)
	var v: FluidField = FluidField.new(taille, taille)
	var centre: float = (taille - 1) * 0.5
	for y: int in taille:
		for x: int in taille:
			var ecart: Vector2 = Vector2(x - centre, y - centre)
			var force: float = exp(-ecart.length_squared() / (taille * taille * 0.05))
			u.put(x, y, ecart.x * force)
			v.put(x, y, ecart.y * force)
	return [u, v]


func test_un_courant_uniforme_n_a_pas_de_divergence() -> void:
	var u: FluidField = FluidField.new(16, 16)
	u.fill(3.0)
	var sortie: FluidField = FluidField.new(16, 16)
	_divergence(sortie, u, FluidField.new(16, 16))
	assert_float(_efficace(sortie)).is_equal(0.0)


func test_une_source_a_de_la_divergence_positive() -> void:
	var champs: Array[FluidField] = _source(32)
	var sortie: FluidField = FluidField.new(32, 32)
	_divergence(sortie, champs[0], champs[1])
	assert_float(sortie.at(16, 16)).is_greater(0.5)


func test_la_pression_efface_presque_toute_la_divergence() -> void:
	var champs: Array[FluidField] = _source(32)
	var avant: FluidField = FluidField.new(32, 32)
	var apres: FluidField = FluidField.new(32, 32)
	var pression: FluidField = FluidField.new(32, 32)
	_divergence(avant, champs[0], champs[1])
	_pression(pression, avant, 200, 1.7)
	_pente(champs[0], champs[1], pression)
	_divergence(apres, champs[0], champs[1])
	assert_float(_efficace(apres)).is_less(_efficace(avant) * 0.25)


## Ce qui reste de divergence après `passes` passes, à la surrelaxation `relaxation`.
func _reste(passes: int, relaxation: float) -> float:
	var champs: Array[FluidField] = _source(32)
	var divergence: FluidField = FluidField.new(32, 32)
	var pression: FluidField = FluidField.new(32, 32)
	_divergence(divergence, champs[0], champs[1])
	_pression(pression, divergence, passes, relaxation)
	_pente(champs[0], champs[1], pression)
	_divergence(divergence, champs[0], champs[1])
	return _efficace(divergence)


func test_surrelaxee_elle_y_arrive_en_moins_de_passes() -> void:
	assert_float(_reste(12, 1.7)).is_less(_reste(12, 1.0))


## Une ronde fermée, nulle aux bords, tirée d'une fonction de courant : sa divergence est nulle par construction.
func _ronde(taille: int) -> Array[FluidField]:
	var courant: FluidField = FluidField.new(taille, taille)
	for y: int in taille:
		for x: int in taille:
			courant.put(x, y, pow(sin(PI * x / (taille - 1)) * sin(PI * y / (taille - 1)), 2.0) * 20.0)
	var u: FluidField = FluidField.new(taille, taille)
	var v: FluidField = FluidField.new(taille, taille)
	for y: int in taille:
		for x: int in taille:
			u.put(x, y, 0.5 * (courant.at(x, y + 1) - courant.at(x, y - 1)))
			v.put(x, y, -0.5 * (courant.at(x + 1, y) - courant.at(x - 1, y)))
	return [u, v]


func test_un_courant_sans_divergence_ne_change_pas() -> void:
	var champs: Array[FluidField] = _ronde(24)
	var avant: float = champs[0].at(12, 6)
	var divergence: FluidField = FluidField.new(24, 24)
	var pression: FluidField = FluidField.new(24, 24)
	_divergence(divergence, champs[0], champs[1])
	_pression(pression, divergence, 20, 1.7)
	_pente(champs[0], champs[1], pression)
	assert_float(champs[0].at(12, 6)).is_equal_approx(avant, 0.001)
#@ 6+


func test_un_mur_garde_une_vitesse_nulle() -> void:
	var murs: ObstacleMask = ObstacleMask.new(24, 24)
	murs.add_box(12, 0, 13, 23)
	var u: FluidField = FluidField.new(24, 24)
	var v: FluidField = FluidField.new(24, 24)
	u.fill(4.0)
	murs.clear_inside(u)
	var divergence: FluidField = FluidField.new(24, 24)
	var pression: FluidField = FluidField.new(24, 24)
	FluidProjection.divergence(divergence, u, v, murs)
	FluidProjection.solve_pressure(pression, divergence, murs, 120, 1.7)
	FluidProjection.subtract_gradient(u, v, pression, murs)
	assert_float(u.at(12, 12)).is_equal(0.0)
	assert_float(u.at(13, 12)).is_equal(0.0)


func test_le_courant_contourne_un_mur() -> void:
	var murs: ObstacleMask = ObstacleMask.new(24, 24)
	murs.add_box(12, 8, 13, 15)
	var u: FluidField = FluidField.new(24, 24)
	var v: FluidField = FluidField.new(24, 24)
	for y: int in 24:
		for x: int in 10:
			u.put(x, y, 4.0)
	var divergence: FluidField = FluidField.new(24, 24)
	var pression: FluidField = FluidField.new(24, 24)
	FluidProjection.divergence(divergence, u, v, murs)
	FluidProjection.solve_pressure(pression, divergence, murs, 200, 1.7)
	FluidProjection.subtract_gradient(u, v, pression, murs)
	assert_float(u.at(12, 4)).is_greater(0.05)
	assert_float(absf(v.at(11, 7))).is_greater(0.001)
#@ all
