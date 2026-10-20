extends GdUnitTestSuite
## Règles de la lecture d'image : au coin d'un pixel, sa couleur ; entre deux pixels, le mélange ; hors de
## l'image, noir ; sur le bord droit et le bord bas, aucune lecture hors de l'image.
#@ 8+
## Lecture centrée : le centre du carré tombe au milieu de l'image, et hors du carré, la couleur du bord.
#@ all


## Une image de 2 × 2 : noir, blanc en haut ; rouge, vert en bas.
func _image() -> Image:
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 0, Color.BLACK)
	image.set_pixel(1, 0, Color.WHITE)
	image.set_pixel(0, 1, Color.RED)
	image.set_pixel(1, 1, Color.GREEN)
	return image


func test_au_coin_d_un_pixel_sa_couleur() -> void:
	assert_that(ImageSampling.bilinear(_image(), Vector2(0.0, 0.0))).is_equal(Color.BLACK)
	assert_that(ImageSampling.bilinear(_image(), Vector2(0.0, 0.5))).is_equal(Color.RED)


func test_entre_deux_pixels_le_melange() -> void:
	var middle := ImageSampling.bilinear(_image(), Vector2(0.25, 0.0))
	assert_float(middle.r).is_equal_approx(0.5, 0.01)
	assert_float(middle.g).is_equal_approx(0.5, 0.01)


func test_hors_de_l_image_noir() -> void:
	assert_that(ImageSampling.bilinear(_image(), Vector2(-0.1, 0.5))).is_equal(Color.BLACK)
	assert_that(ImageSampling.bilinear(_image(), Vector2(0.5, 1.0))).is_equal(Color.BLACK)


func test_sur_le_bord_la_lecture_reste_dans_l_image() -> void:
	# Au dernier pixel, le voisin de droite et celui du dessous sont ce pixel même : pas d'erreur, sa couleur.
	assert_that(ImageSampling.bilinear(_image(), Vector2(0.99, 0.99))).is_equal(Color.GREEN)
#@ 8+


func test_le_centre_du_carre_tombe_au_milieu_de_l_image() -> void:
	var image := _image()
	assert_that(ImageSampling.centered(image, Vector2.ZERO, Vector2(10.0, 10.0))).is_equal(
		ImageSampling.bilinear(image, Vector2(0.5, 0.5)))


func test_hors_du_carre_la_couleur_du_bord() -> void:
	# Loin à droite, sur la ligne du haut : le pixel du bord droit, blanc ; loin en bas à gauche : rouge.
	assert_that(ImageSampling.centered(_image(), Vector2(100.0, -5.0), Vector2(10.0, 10.0))).is_equal(Color.WHITE)
	assert_that(ImageSampling.centered(_image(), Vector2(-100.0, 100.0), Vector2(10.0, 10.0))).is_equal(Color.RED)
#@ all
