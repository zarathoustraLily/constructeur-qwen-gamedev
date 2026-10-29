extends GdUnitTestSuite
## Règles d'une jauge : la part remplie suit la valeur, bornée de 0 à 1 ; après une perte, la traîne garde l'ancienne
## valeur pendant son délai, puis la rejoint à sa vitesse, sans descendre sous la part remplie ; un gain remonte la
## traîne avec la valeur ; un maximum nul donne une jauge vide ; poser d'un coup ne laisse aucune traîne.

var _bar: StatBar


func before_test() -> void:
	_bar = auto_free(StatBar.new())
	_bar.trail_delay = 0.5
	_bar.trail_speed = 1.0
	add_child(_bar)


func test_la_part_remplie_suit_la_valeur_bornee() -> void:
	_bar.set_values(30.0, 100.0)
	assert_float(_bar.ratio).is_equal_approx(0.3, 0.0001)
	_bar.set_values(150.0, 100.0)
	assert_float(_bar.ratio).is_equal(1.0)
	_bar.set_values(-5.0, 100.0)
	assert_float(_bar.ratio).is_equal(0.0)


func test_apres_une_perte_la_traine_attend_puis_rejoint() -> void:
	_bar.set_values(100.0, 100.0)
	_bar.set_values(60.0, 100.0)
	_bar.advance(0.4)
	assert_float(_bar.trail_ratio).is_equal(1.0)
	_bar.advance(0.2)
	assert_float(_bar.trail_ratio).is_equal_approx(0.9, 0.0001)
	_bar.advance(5.0)
	assert_float(_bar.trail_ratio).is_equal_approx(0.6, 0.0001)


func test_un_gain_remonte_la_traine_avec_la_valeur() -> void:
	_bar.set_values(20.0, 100.0)
	_bar.advance(10.0)
	_bar.set_values(70.0, 100.0)
	assert_float(_bar.ratio).is_equal_approx(0.7, 0.0001)
	assert_float(_bar.trail_ratio).is_equal_approx(0.7, 0.0001)


func test_un_maximum_nul_donne_une_jauge_vide() -> void:
	_bar.set_values(10.0, 0.0)
	assert_float(_bar.ratio).is_equal(0.0)


func test_poser_d_un_coup_ne_laisse_aucune_traine() -> void:
	_bar.snap(0.0, 100.0)
	assert_float(_bar.ratio).is_equal(0.0)
	assert_float(_bar.trail_ratio).is_equal(0.0)
