extends GdUnitTestSuite
## Règles de la diffusion : un taux nul ne change rien ; une bosse s'aplatit et s'élargit ; le total se conserve ; même un taux
## énorme reste stable ; plus le taux est fort, plus la bosse s'aplatit.


func _bosse() -> FluidField:
	var champ: FluidField = FluidField.new(16, 16)
	champ.put(8, 8, 1.0)
	return champ


func test_un_taux_nul_ne_change_rien() -> void:
	var cible: FluidField = FluidField.new(16, 16)
	Diffusion.solve(cible, _bosse(), 0.0, 0.1, 10)
	assert_float(cible.at(8, 8)).is_equal(1.0)


func test_une_bosse_s_aplatit_et_s_elargit() -> void:
	var cible: FluidField = FluidField.new(16, 16)
	Diffusion.solve(cible, _bosse(), 1.0, 0.1, 20)
	assert_float(cible.at(8, 8)).is_less(1.0)
	assert_float(cible.at(9, 8)).is_greater(0.0)


func test_le_total_se_conserve() -> void:
	var cible: FluidField = FluidField.new(16, 16)
	Diffusion.solve(cible, _bosse(), 1.0, 0.1, 40)
	assert_float(cible.total()).is_equal_approx(1.0, 0.02)


func test_meme_un_taux_enorme_reste_stable() -> void:
	var cible: FluidField = FluidField.new(16, 16)
	Diffusion.solve(cible, _bosse(), 1000.0, 1.0, 20)
	assert_float(cible.peak()).is_less_equal(1.0)
	assert_float(cible.at(0, 0)).is_greater_equal(0.0)


func test_plus_le_taux_est_fort_plus_la_bosse_s_aplatit() -> void:
	var faible: FluidField = FluidField.new(16, 16)
	var fort: FluidField = FluidField.new(16, 16)
	Diffusion.solve(faible, _bosse(), 0.5, 0.1, 20)
	Diffusion.solve(fort, _bosse(), 5.0, 0.1, 20)
	assert_float(fort.peak()).is_less(faible.peak())
