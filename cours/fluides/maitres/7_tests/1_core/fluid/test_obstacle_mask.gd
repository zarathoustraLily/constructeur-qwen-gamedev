extends GdUnitTestSuite
## Règles des murs : une grille neuve est libre ; hors de la grille, c'est plein ; un rectangle se remplit, bornes comprises, et
## s'arrête au bord ; un mur vide le champ à sa place, et seulement là ; une vitesse qui entre dans un mur s'arrête, celle qui
## s'en éloigne reste.


func test_une_grille_neuve_est_libre() -> void:
	assert_bool(ObstacleMask.new(4, 4).is_solid(2, 2)).is_false()


func test_hors_de_la_grille_c_est_plein() -> void:
	var murs: ObstacleMask = ObstacleMask.new(4, 4)
	assert_bool(murs.is_solid(-1, 2)).is_true()
	assert_bool(murs.is_solid(2, 4)).is_true()


func test_un_rectangle_se_remplit_bornes_comprises() -> void:
	var murs: ObstacleMask = ObstacleMask.new(8, 8)
	murs.add_box(2, 3, 4, 5)
	assert_bool(murs.is_solid(2, 3)).is_true()
	assert_bool(murs.is_solid(4, 5)).is_true()
	assert_bool(murs.is_solid(5, 5)).is_false()
	assert_bool(murs.is_solid(1, 3)).is_false()


func test_un_rectangle_s_arrete_au_bord() -> void:
	var murs: ObstacleMask = ObstacleMask.new(4, 4)
	murs.add_box(-3, -3, 9, 0)
	assert_bool(murs.is_solid(3, 0)).is_true()
	assert_bool(murs.is_solid(3, 1)).is_false()


func test_une_vitesse_qui_entre_dans_un_mur_s_arrete() -> void:
	var murs: ObstacleMask = ObstacleMask.new(6, 6)
	murs.add_box(3, 0, 3, 5)
	var u: FluidField = FluidField.new(6, 6)
	var v: FluidField = FluidField.new(6, 6)
	u.fill(2.0)
	v.fill(1.0)
	murs.stop_at_walls(u, v)
	assert_float(u.at(2, 3)).is_equal(0.0)
	assert_float(u.at(1, 3)).is_equal(2.0)
	assert_float(u.at(5, 3)).is_equal(0.0)
	assert_float(v.at(2, 5)).is_equal(0.0)
	assert_float(v.at(2, 2)).is_equal(1.0)


func test_une_vitesse_qui_s_eloigne_d_un_mur_reste() -> void:
	var murs: ObstacleMask = ObstacleMask.new(6, 6)
	murs.add_box(3, 0, 3, 5)
	var u: FluidField = FluidField.new(6, 6)
	u.fill(-2.0)
	murs.stop_at_walls(u, FluidField.new(6, 6))
	assert_float(u.at(2, 3)).is_equal(-2.0)
	assert_float(u.at(4, 3)).is_equal(0.0)


func test_un_mur_vide_le_champ_a_sa_place_seulement() -> void:
	var murs: ObstacleMask = ObstacleMask.new(4, 4)
	murs.add_box(1, 1, 1, 1)
	var champ: FluidField = FluidField.new(4, 4)
	champ.fill(2.0)
	murs.clear_inside(champ)
	assert_float(champ.at(1, 1)).is_equal(0.0)
	assert_float(champ.at(2, 1)).is_equal(2.0)
