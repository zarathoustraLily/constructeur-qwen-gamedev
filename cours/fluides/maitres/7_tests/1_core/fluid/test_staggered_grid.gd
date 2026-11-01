extends GdUnitTestSuite
## Règles de la grille décalée. `u` a une colonne de plus, `v` une ligne de plus. La divergence compte les quatre faces d'une case. La
## projection annule la divergence, même sur des vagues serrées où la grille de l'étape 13 garde un résidu, et plus de passes la font
## encore baisser ; un courant déjà sans divergence ne change pas ; rien ne traverse le bord. La vitesse se lit entre les faces, et elle
## se transporte elle-même : un courant uniforme ne change pas, et un tourbillon garde son sens.
#@ 25+
## Pour un liquide, seules les cases d'eau prennent de la pression : l'air compte pour zéro, un mur ne compte pas, et la divergence
## disparaît de l'eau.
#@ all

const WIDTH := 30
const HEIGHT := 22


## Une grille pleine de vagues serrées, comme celles des tests de l'étape 13.
func _waves() -> StaggeredGrid:
	var grid: StaggeredGrid = StaggeredGrid.new(WIDTH, HEIGHT)
	for y: int in HEIGHT:
		for x: int in WIDTH + 1:
			grid.u.put(x, y, 5.0 * sin(0.73 * x + 0.21) * cos(0.41 * y - 0.17))
	for y: int in HEIGHT + 1:
		for x: int in WIDTH:
			grid.v.put(x, y, -3.0 * sin(0.73 * x + 0.21) * cos(0.41 * y - 0.17))
	return grid


func test_u_a_une_colonne_de_plus_et_v_une_ligne_de_plus() -> void:
	var grid: StaggeredGrid = StaggeredGrid.new(4, 3)
	assert_int(grid.u.width).is_equal(5)
	assert_int(grid.u.height).is_equal(3)
	assert_int(grid.v.width).is_equal(4)
	assert_int(grid.v.height).is_equal(4)
	assert_int(grid.pressure.width).is_equal(4)
	assert_int(grid.pressure.height).is_equal(3)


func test_la_divergence_compte_les_quatre_faces() -> void:
	var grid: StaggeredGrid = StaggeredGrid.new(4, 4)
	grid.u.put(2, 1, 1.0)
	grid.u.put(1, 1, 3.0)
	grid.v.put(1, 2, 5.0)
	grid.v.put(1, 1, 2.0)
	assert_float(grid.divergence_at(1, 1)).is_equal_approx(1.0, 0.0001)


func test_la_plus_grande_divergence_oublie_le_signe() -> void:
	var grid: StaggeredGrid = StaggeredGrid.new(4, 4)
	grid.u.put(1, 1, 7.0)
	assert_float(grid.largest_divergence()).is_equal_approx(7.0, 0.0001)


func test_fermer_le_bord_annule_ses_faces_seulement() -> void:
	var grid: StaggeredGrid = _waves()
	var dedans: float = grid.u.at(3, 3)
	grid.close_border()
	assert_float(grid.u.at(0, 3)).is_equal(0.0)
	assert_float(grid.u.at(WIDTH, 3)).is_equal(0.0)
	assert_float(grid.v.at(3, 0)).is_equal(0.0)
	assert_float(grid.v.at(3, HEIGHT)).is_equal(0.0)
	assert_float(grid.u.at(3, 3)).is_equal(dedans)


func test_la_projection_annule_la_divergence_sur_des_vagues_serrees() -> void:
	var grid: StaggeredGrid = _waves()
	grid.project(300, 1.8)
	assert_float(grid.largest_divergence()).is_less(0.001)


func test_plus_de_passes_font_encore_baisser_la_divergence() -> void:
	var peu: StaggeredGrid = _waves()
	peu.project(30, 1.8)
	var beaucoup: StaggeredGrid = _waves()
	beaucoup.project(120, 1.8)
	assert_float(beaucoup.largest_divergence()).is_less(peu.largest_divergence() * 0.5)


func test_un_courant_sans_divergence_ne_change_pas() -> void:
	var grid: StaggeredGrid = _waves()
	grid.project(300, 1.8)
	var avant: float = grid.u.at(10, 10)
	grid.pressure.fill(0.0)
	grid.project(100, 1.8)
	assert_float(grid.u.at(10, 10)).is_equal_approx(avant, 0.01)


func test_rien_ne_traverse_le_bord_apres_une_projection() -> void:
	var grid: StaggeredGrid = _waves()
	grid.project(60, 1.8)
	for y: int in HEIGHT:
		assert_float(grid.u.at(0, y)).is_equal(0.0)
		assert_float(grid.u.at(WIDTH, y)).is_equal(0.0)


func test_la_pente_retire_l_ecart_entre_les_deux_cases_d_une_face() -> void:
	var grid: StaggeredGrid = StaggeredGrid.new(4, 4)
	grid.pressure.put(2, 1, 3.0)
	grid.pressure.put(1, 1, 1.0)
	grid.subtract_gradient()
	assert_float(grid.u.at(2, 1)).is_equal_approx(-2.0, 0.0001)
	assert_float(grid.v.at(2, 1)).is_equal_approx(-3.0, 0.0001)


func test_une_case_du_coin_n_a_que_deux_voisines() -> void:
	var grid: StaggeredGrid = StaggeredGrid.new(4, 4)
	grid.pressure.put(1, 0, 2.0)
	grid.pressure.put(0, 1, 4.0)
	grid.u.put(1, 0, 2.0)
	assert_float(grid.call("_settled", 0, 0)).is_equal_approx(2.0, 0.0001)


func test_la_vitesse_se_lit_entre_les_faces() -> void:
	var grid: StaggeredGrid = StaggeredGrid.new(4, 4)
	grid.u.put(2, 1, 4.0)
	grid.u.put(3, 1, 8.0)
	grid.v.put(1, 2, 6.0)
	grid.v.put(1, 3, 2.0)
	assert_float(grid.velocity_at(2.0, 1.0).x).is_equal_approx(6.0, 0.0001)
	assert_float(grid.velocity_at(1.0, 2.0).y).is_equal_approx(4.0, 0.0001)


func test_un_courant_uniforme_se_transporte_sans_changer() -> void:
	var grid: StaggeredGrid = StaggeredGrid.new(12, 12)
	grid.u.fill(3.0)
	grid.transport(0.2)
	assert_float(grid.u.at(6, 6)).is_equal_approx(3.0, 0.0001)
	assert_float(grid.v.at(6, 6)).is_equal(0.0)


func test_une_bosse_de_vitesse_est_emportee_par_le_courant() -> void:
	var grid: StaggeredGrid = StaggeredGrid.new(24, 8)
	grid.u.fill(10.0)
	for y: int in 8:
		grid.u.put(6, y, 14.0)
	grid.transport(0.5)
	assert_float(grid.u.at(11, 3)).is_equal_approx(14.0, 0.0001)
	assert_float(grid.u.at(6, 3)).is_equal_approx(10.0, 0.0001)


func test_un_tourbillon_garde_son_sens() -> void:
	var grid: StaggeredGrid = StaggeredGrid.new(24, 24)
	for y: int in 24:
		for x: int in 25:
			grid.u.put(x, y, 0.5 * (y - 11.5))
	for y: int in 25:
		for x: int in 24:
			grid.v.put(x, y, -0.5 * (x - 11.5))
	grid.project(200, 1.8)
	for _i: int in 4:
		grid.transport(0.1)
		grid.project(60, 1.8)
	assert_float(grid.u.at(12, 20)).is_greater(0.0)
	assert_float(grid.u.at(12, 3)).is_less(0.0)
#@ 25+


## Une grille dont le masque remplit les cases de `first` à `last`.
func _water(columns: int, rows: int, first: Vector2i, last: Vector2i) -> PackedByteArray:
	var full: PackedByteArray = PackedByteArray()
	full.resize(columns * rows)
	full.fill(0)
	for y: int in range(first.y, last.y + 1):
		for x: int in range(first.x, last.x + 1):
			full[y * columns + x] = 1
	return full


func test_seule_une_case_d_eau_prend_de_la_pression() -> void:
	var grid: StaggeredGrid = StaggeredGrid.new(6, 6)
	var full: PackedByteArray = _water(6, 6, Vector2i(2, 2), Vector2i(3, 3))
	grid.v.put(2, 3, 4.0)
	grid.solve_water_pressure(full, 20, 1.0)
	assert_float(grid.pressure.at(2, 2)).is_not_equal(0.0)
	assert_float(grid.pressure.at(0, 0)).is_equal(0.0)
	assert_float(grid.pressure.at(4, 2)).is_equal(0.0)


func test_l_air_compte_pour_zero_et_un_mur_ne_compte_pas() -> void:
	var grid: StaggeredGrid = StaggeredGrid.new(4, 4)
	var full: PackedByteArray = _water(4, 4, Vector2i(0, 0), Vector2i(1, 0))
	grid.pressure.put(1, 0, 3.0)
	grid.u.put(1, 0, 1.0)
	assert_float(grid.call("_settled_in_water", full, 0, 0)).is_equal_approx(1.0, 0.0001)


func test_la_divergence_disparait_de_l_eau() -> void:
	var grid: StaggeredGrid = StaggeredGrid.new(12, 10)
	var full: PackedByteArray = _water(12, 10, Vector2i(0, 4), Vector2i(11, 9))
	for y: int in 11:
		for x: int in 12:
			grid.v.put(x, y, 3.0 * sin(0.9 * x))
	grid.close_border()
	grid.solve_water_pressure(full, 200, 1.7)
	grid.subtract_water_gradient(full)
	for y: int in range(4, 10):
		for x: int in 12:
			assert_float(absf(grid.divergence_at(x, y))).is_less(0.01)


func test_une_face_loin_de_l_eau_garde_sa_vitesse() -> void:
	var grid: StaggeredGrid = StaggeredGrid.new(6, 6)
	var full: PackedByteArray = _water(6, 6, Vector2i(0, 0), Vector2i(1, 1))
	grid.u.put(4, 4, 2.0)
	grid.pressure.put(0, 0, 9.0)
	grid.subtract_water_gradient(full)
	assert_float(grid.u.at(4, 4)).is_equal(2.0)
#@ all
