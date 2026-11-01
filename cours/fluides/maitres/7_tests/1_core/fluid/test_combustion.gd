extends GdUnitTestSuite
## Règles du feu : rien ne brûle sous la température d'allumage ; au-dessus, le carburant se change en chaleur et en suie, sans
## brûler plus qu'il n'y en a ; ce qui brûle dilate le gaz ; l'air chaud monte, la suie pèse ; la chaleur se perd à la même
## vitesse quelle que soit la cadence.


func _reglages() -> FireSettings:
	var reglages: FireSettings = FireSettings.new()
	reglages.ignition = 0.5
	reglages.burn_rate = 2.0
	reglages.heat = 3.0
	reglages.soot_yield = 0.5
	reglages.expansion = 0.25
	reglages.buoyancy = 10.0
	reglages.soot_weight = 4.0
	return reglages


func _champ(valeur: float) -> FluidField:
	var champ: FluidField = FluidField.new(2, 2)
	champ.fill(valeur)
	return champ


func test_rien_ne_brule_sous_la_temperature_d_allumage() -> void:
	var carburant: FluidField = _champ(1.0)
	var chaleur: FluidField = _champ(0.2)
	Combustion.burn(carburant, chaleur, _champ(0.0), _champ(0.0), _reglages(), 0.1)
	assert_float(carburant.at(0, 0)).is_equal(1.0)
	assert_float(chaleur.at(0, 0)).is_equal_approx(0.2, 0.0001)


func test_au_dessus_le_carburant_se_change_en_chaleur_et_en_suie() -> void:
	var carburant: FluidField = _champ(1.0)
	var chaleur: FluidField = _champ(1.0)
	var suie: FluidField = _champ(0.0)
	Combustion.burn(carburant, chaleur, suie, _champ(0.0), _reglages(), 0.1)
	assert_float(carburant.at(0, 0)).is_equal_approx(0.8, 0.0001)
	assert_float(chaleur.at(0, 0)).is_equal_approx(1.6, 0.0001)
	assert_float(suie.at(0, 0)).is_equal_approx(0.1, 0.0001)


func test_on_ne_brule_pas_plus_qu_il_n_y_en_a() -> void:
	var carburant: FluidField = _champ(0.05)
	Combustion.burn(carburant, _champ(1.0), _champ(0.0), _champ(0.0), _reglages(), 1.0)
	assert_float(carburant.at(0, 0)).is_equal(0.0)


func test_ce_qui_brule_dilate_le_gaz() -> void:
	var dilatation: FluidField = _champ(9.0)
	Combustion.burn(_champ(1.0), _champ(1.0), _champ(0.0), dilatation, _reglages(), 0.1)
	assert_float(dilatation.at(0, 0)).is_equal_approx(0.5, 0.0001)
	Combustion.burn(_champ(0.0), _champ(1.0), _champ(0.0), dilatation, _reglages(), 0.1)
	assert_float(dilatation.at(0, 0)).is_equal(0.0)


func test_l_air_chaud_monte_et_la_suie_pese() -> void:
	var v: FluidField = _champ(0.0)
	Combustion.lift(v, _champ(1.0), _champ(0.0), _reglages(), 0.1)
	assert_float(v.at(0, 0)).is_equal_approx(-1.0, 0.0001)
	v.fill(0.0)
	Combustion.lift(v, _champ(0.0), _champ(1.0), _reglages(), 0.1)
	assert_float(v.at(0, 0)).is_equal_approx(0.4, 0.0001)


func test_la_chaleur_se_perd_a_la_meme_vitesse_quelle_que_soit_la_cadence() -> void:
	var lent: FluidField = _champ(1.0)
	var rapide: FluidField = _champ(1.0)
	Combustion.cool(lent, 2.0, 0.2)
	for _i: int in 4:
		Combustion.cool(rapide, 2.0, 0.05)
	assert_float(rapide.at(0, 0)).is_equal_approx(lent.at(0, 0), 0.0001)
	assert_float(lent.at(0, 0)).is_equal_approx(exp(-0.4), 0.0001)
