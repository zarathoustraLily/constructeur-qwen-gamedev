extends GdUnitTestSuite
## Règles du rangement : les images vont de gauche à droite, puis de haut en bas ; une image occupe un rectangle de la planche ; la
## partie fractionnaire dit le mélange ; une boucle repart de zéro ; sans boucle, la dernière image reste.


func test_les_images_vont_de_gauche_a_droite_puis_de_haut_en_bas() -> void:
	assert_vector(Flipbook.cell(0, 4)).is_equal(Vector2i(0, 0))
	assert_vector(Flipbook.cell(3, 4)).is_equal(Vector2i(3, 0))
	assert_vector(Flipbook.cell(4, 4)).is_equal(Vector2i(0, 1))
	assert_vector(Flipbook.cell(9, 4)).is_equal(Vector2i(1, 2))


func test_une_image_occupe_son_rectangle_de_la_planche() -> void:
	var rectangle: Rect2 = Flipbook.uv_rect(5, 4, 2)
	assert_vector(rectangle.position).is_equal_approx(Vector2(0.25, 0.5), Vector2(0.0001, 0.0001))
	assert_vector(rectangle.size).is_equal_approx(Vector2(0.25, 0.5), Vector2(0.0001, 0.0001))


func test_la_partie_fractionnaire_dit_le_melange() -> void:
	assert_float(Flipbook.frame_at(0.125, 10.0, 16, false)).is_equal_approx(1.25, 0.0001)


func test_une_boucle_repart_de_zero() -> void:
	assert_float(Flipbook.frame_at(2.0, 10.0, 16, true)).is_equal_approx(4.0, 0.0001)


func test_sans_boucle_la_derniere_image_reste() -> void:
	assert_float(Flipbook.frame_at(100.0, 10.0, 16, false)).is_equal(15.0)
