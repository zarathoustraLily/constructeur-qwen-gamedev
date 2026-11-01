extends GdUnitTestSuite
## Règles du champ : il commence à zéro ; une case se pose et se relit ; hors de la grille, on lit le bord ; entre deux cases,
## on lit leur mélange ; le total et le plus haut se comptent ; une recopie est exacte ; un disque est plus fort au centre et
## s'arrête au rayon.


func test_il_commence_a_zero() -> void:
	var champ: FluidField = FluidField.new(4, 3)
	assert_int(champ.data.size()).is_equal(12)
	assert_float(champ.total()).is_equal(0.0)


func test_une_case_se_pose_et_se_relit_a_sa_place() -> void:
	var champ: FluidField = FluidField.new(4, 3)
	champ.put(2, 1, 5.0)
	assert_float(champ.at(2, 1)).is_equal(5.0)
	assert_int(champ.index(2, 1)).is_equal(6)
	assert_float(champ.data[6]).is_equal(5.0)


func test_hors_de_la_grille_on_lit_le_bord() -> void:
	var champ: FluidField = FluidField.new(4, 3)
	champ.put(0, 0, 7.0)
	champ.put(3, 2, 9.0)
	assert_float(champ.at(-5, -1)).is_equal(7.0)
	assert_float(champ.at(10, 9)).is_equal(9.0)


func test_entre_deux_cases_on_lit_leur_melange() -> void:
	var champ: FluidField = FluidField.new(2, 2)
	champ.put(1, 0, 1.0)
	champ.put(1, 1, 1.0)
	assert_float(champ.sample(0.25, 0.5)).is_equal_approx(0.25, 0.0001)
	champ.put(0, 1, 1.0)
	assert_float(champ.sample(0.0, 0.5)).is_equal_approx(0.5, 0.0001)
	assert_float(champ.sample(1.0, 1.0)).is_equal_approx(1.0, 0.0001)


func test_le_total_et_le_plus_haut_se_comptent() -> void:
	var champ: FluidField = FluidField.new(3, 3)
	champ.put(0, 0, 2.0)
	champ.put(2, 2, 3.0)
	assert_float(champ.total()).is_equal_approx(5.0, 0.0001)
	assert_float(champ.peak()).is_equal(3.0)


func test_une_recopie_est_exacte_et_ne_partage_rien() -> void:
	var champ: FluidField = FluidField.new(3, 3)
	var copie: FluidField = FluidField.new(3, 3)
	champ.fill(2.0)
	copie.copy_from(champ)
	champ.put(1, 1, 9.0)
	assert_float(copie.at(1, 1)).is_equal(2.0)
	assert_float(copie.total()).is_equal_approx(18.0, 0.0001)


func test_un_disque_est_plus_fort_au_centre_et_s_arrete_au_rayon() -> void:
	var champ: FluidField = FluidField.new(20, 20)
	champ.add_disc(10.0, 10.0, 4.0, 2.0)
	assert_float(champ.at(10, 10)).is_equal_approx(2.0, 0.0001)
	assert_float(champ.at(12, 10)).is_equal_approx(1.0, 0.0001)
	assert_float(champ.at(14, 10)).is_equal(0.0)


func test_un_disque_au_bord_ne_sort_pas_de_la_grille() -> void:
	var champ: FluidField = FluidField.new(8, 8)
	champ.add_disc(0.0, 7.0, 3.0, 1.0)
	assert_float(champ.at(0, 7)).is_equal_approx(1.0, 0.0001)
