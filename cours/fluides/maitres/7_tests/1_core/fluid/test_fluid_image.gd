extends GdUnitTestSuite
## Règles de l'image : elle a la taille du champ ; 0 est noir, `brightest` est blanc, le milieu est gris, et au-delà reste blanc.
#@ 10+
## En couleurs, chaque case lit le dégradé à la hauteur de sa valeur.
#@ all


func test_elle_a_la_taille_du_champ() -> void:
	var image: Image = FluidImage.gray(FluidField.new(6, 4), 1.0)
	assert_int(image.get_width()).is_equal(6)
	assert_int(image.get_height()).is_equal(4)


func test_zero_est_noir_le_plus_clair_blanc_le_milieu_gris() -> void:
	var champ: FluidField = FluidField.new(3, 1)
	champ.put(1, 0, 1.0)
	champ.put(2, 0, 2.0)
	var image: Image = FluidImage.gray(champ, 2.0)
	assert_float(image.get_pixel(0, 0).r).is_equal(0.0)
	assert_float(image.get_pixel(1, 0).r).is_equal_approx(0.5, 0.01)
	assert_float(image.get_pixel(2, 0).r).is_equal(1.0)


func test_au_dela_du_plus_clair_on_reste_blanc() -> void:
	var champ: FluidField = FluidField.new(1, 1)
	champ.put(0, 0, 9.0)
	assert_float(FluidImage.gray(champ, 2.0).get_pixel(0, 0).r).is_equal(1.0)
#@ 10+


func test_en_couleurs_chaque_case_lit_le_degrade() -> void:
	var degrade: Gradient = Gradient.new()
	degrade.set_color(0, Color.BLACK)
	degrade.set_color(1, Color.RED)
	var champ: FluidField = FluidField.new(2, 1)
	champ.put(1, 0, 1.0)
	var image: Image = FluidImage.colored(champ, degrade, 1.0)
	assert_float(image.get_pixel(0, 0).r).is_equal(0.0)
	assert_float(image.get_pixel(1, 0).r).is_equal(1.0)
	assert_float(image.get_pixel(1, 0).g).is_equal(0.0)
#@ all
