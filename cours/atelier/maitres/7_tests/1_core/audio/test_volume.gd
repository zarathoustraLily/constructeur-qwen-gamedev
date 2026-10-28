extends GdUnitTestSuite
## Règles des conversions de volume : un curseur à moitié vaut environ -6 dB, un curseur à zéro coupe le son,
## le pourcentage s'arrondit, un pas de curseur reste entre 0 et 1.


func test_a_zero_le_volume_est_au_plancher() -> void:
	assert_float(Volume.to_db(0.0)).is_equal(Volume.FLOOR_DB)
	assert_float(Volume.to_db(-0.5)).is_equal(Volume.FLOOR_DB)


func test_plein_volume_vaut_zero_decibel_et_moitie_environ_moins_six() -> void:
	assert_float(Volume.to_db(1.0)).is_equal_approx(0.0, 0.001)
	assert_float(Volume.to_db(0.5)).is_equal_approx(-6.0206, 0.001)


func test_un_volume_infime_ne_descend_pas_sous_le_plancher() -> void:
	assert_float(Volume.to_db(0.00001)).is_equal(Volume.FLOOR_DB)


func test_retour_des_decibels_au_curseur() -> void:
	assert_float(Volume.to_linear(-6.0206)).is_equal_approx(0.5, 0.001)
	assert_float(Volume.to_linear(0.0)).is_equal_approx(1.0, 0.001)
	assert_float(Volume.to_linear(Volume.FLOOR_DB)).is_equal(0.0)
	assert_float(Volume.to_linear(-80.0)).is_equal(0.0)


func test_au_dessus_de_zero_decibel_le_curseur_reste_a_un() -> void:
	assert_float(Volume.to_linear(6.0)).is_equal(1.0)


func test_le_pourcentage_s_arrondit() -> void:
	assert_str(Volume.percent_text(0.75)).is_equal("75 %")
	assert_str(Volume.percent_text(0.333)).is_equal("33 %")
	assert_str(Volume.percent_text(1.4)).is_equal("100 %")


func test_un_pas_de_curseur_reste_entre_zero_et_un() -> void:
	assert_float(Volume.step_value(0.5, 0.05, 0.05)).is_equal_approx(0.55, 0.0001)
	assert_float(Volume.step_value(0.98, 0.05, 0.05)).is_equal(1.0)
	assert_float(Volume.step_value(0.02, -0.05, 0.05)).is_equal(0.0)
