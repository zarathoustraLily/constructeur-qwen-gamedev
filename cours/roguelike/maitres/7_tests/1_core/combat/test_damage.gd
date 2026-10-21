extends GdUnitTestSuite
## Règles du calcul des dégâts : à 100 %, les dégâts de base ; à 150 %, une fois et demie ; à 0 %, rien.


func test_a_cent_pour_cent_les_degats_de_base() -> void:
	assert_float(Damage.scaled(10.0, 100.0)).is_equal(10.0)


func test_a_cent_cinquante_pour_cent_une_fois_et_demie() -> void:
	assert_float(Damage.scaled(14.0, 150.0)).is_equal(21.0)


func test_a_zero_pour_cent_rien() -> void:
	assert_float(Damage.scaled(10.0, 0.0)).is_equal(0.0)
