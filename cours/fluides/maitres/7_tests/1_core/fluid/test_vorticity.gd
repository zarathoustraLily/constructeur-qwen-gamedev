extends GdUnitTestSuite
## Règles des tourbillons : un courant uniforme ne tourne pas ; une rotation d'ensemble a une rotation égale au double de sa
## vitesse angulaire ; le confinement ne touche pas un fluide au repos ; il renforce un tourbillon ; sans force, il ne fait rien.


## Un tourbillon lisse, au centre de la grille.
func _tourbillon(taille: int) -> Array[FluidField]:
	var u: FluidField = FluidField.new(taille, taille)
	var v: FluidField = FluidField.new(taille, taille)
	var centre: float = (taille - 1) * 0.5
	for y: int in taille:
		for x: int in taille:
			var ecart: Vector2 = Vector2(x - centre, y - centre)
			var force: float = exp(-ecart.length_squared() / (taille * taille * 0.04))
			u.put(x, y, -ecart.y * force)
			v.put(x, y, ecart.x * force)
	return [u, v]


func test_un_courant_uniforme_ne_tourne_pas() -> void:
	var u: FluidField = FluidField.new(8, 8)
	u.fill(2.0)
	var sortie: FluidField = FluidField.new(8, 8)
	Vorticity.curl(sortie, u, FluidField.new(8, 8))
	assert_float(sortie.at(4, 4)).is_equal(0.0)


func test_une_rotation_d_ensemble_vaut_le_double_de_sa_vitesse_angulaire() -> void:
	var u: FluidField = FluidField.new(16, 16)
	var v: FluidField = FluidField.new(16, 16)
	for y: int in 16:
		for x: int in 16:
			u.put(x, y, -3.0 * (y - 8.0))
			v.put(x, y, 3.0 * (x - 8.0))
	var sortie: FluidField = FluidField.new(16, 16)
	Vorticity.curl(sortie, u, v)
	assert_float(sortie.at(8, 8)).is_equal_approx(6.0, 0.001)


func test_le_confinement_ne_touche_pas_un_fluide_au_repos() -> void:
	var u: FluidField = FluidField.new(8, 8)
	var v: FluidField = FluidField.new(8, 8)
	Vorticity.confine(u, v, FluidField.new(8, 8), 5.0, 0.1)
	assert_float(u.peak()).is_equal(0.0)
	assert_float(v.peak()).is_equal(0.0)


func test_il_renforce_un_tourbillon() -> void:
	var champs: Array[FluidField] = _tourbillon(32)
	var spin: FluidField = FluidField.new(32, 32)
	Vorticity.curl(spin, champs[0], champs[1])
	var avant: float = spin.peak()
	Vorticity.confine(champs[0], champs[1], spin, 5.0, 0.2)
	Vorticity.curl(spin, champs[0], champs[1])
	assert_float(spin.peak()).is_greater(avant)


func test_sans_force_il_ne_fait_rien() -> void:
	var champs: Array[FluidField] = _tourbillon(16)
	var spin: FluidField = FluidField.new(16, 16)
	Vorticity.curl(spin, champs[0], champs[1])
	var avant: float = champs[0].at(5, 8)
	Vorticity.confine(champs[0], champs[1], spin, 0.0, 0.2)
	assert_float(champs[0].at(5, 8)).is_equal(avant)
