extends GdUnitTestSuite
## Le découpage d'une planche peinte : une pièce par îlot, rognée au plus juste ; deux îlots qui se touchent, même par un
## coin, n'en font qu'un ; un écart choisi regroupe les pièces proches ; les poussières sont ignorées ; une pièce
## n'emporte pas les pixels de sa voisine, même quand leurs cadres se recouvrent ; les pièces se rangent sans se
## chevaucher, alignées sur les blocs de compression ; une pièce trop grande pour une page est refusée. Sur la planche de
## laurent : onze pièces, et la dalle grise, à deux pixels des dalles du haut, reste une pièce à part.

## La planche peinte à la main par laurent : 2000 × 2000 pixels, fond transparent.
const SHEET: String = "res://6_assets/planches_peintes/sol_01.png"


# Une image transparente de `size` pixels, où chaque rectangle de `rects` est opaque, d'une couleur à lui.
func _image(size: Vector2i, rects: Array[Rect2i]) -> Image:
	var image: Image = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	for index: int in rects.size():
		image.fill_rect(rects[index], Color.from_hsv(index * 0.15, 0.8, 0.9))
	return image


func _rects(pieces: Array[SheetPiece]) -> Array[Rect2i]:
	var rects: Array[Rect2i] = []
	for piece: SheetPiece in pieces:
		rects.append(piece.source_rect)
	return rects


func test_une_piece_par_ilot_rognee_au_plus_juste() -> void:
	var pieces: Array[SheetPiece] = SheetImporter.find_pieces(_image(Vector2i(64, 64),
			[Rect2i(30, 30, 8, 8), Rect2i(2, 3, 10, 5)]), 0, 1)
	assert_array(_rects(pieces)).is_equal([Rect2i(2, 3, 10, 5), Rect2i(30, 30, 8, 8)])
	assert_int(pieces[0].area).is_equal(50)
	assert_int(pieces[1].area).is_equal(64)


func test_deux_ilots_qui_se_touchent_par_un_coin_n_en_font_qu_un() -> void:
	var pieces: Array[SheetPiece] = SheetImporter.find_pieces(_image(Vector2i(32, 16),
			[Rect2i(0, 0, 4, 4), Rect2i(4, 4, 4, 4), Rect2i(14, 0, 4, 4)]), 0, 1)
	assert_array(_rects(pieces)).is_equal([Rect2i(0, 0, 8, 8), Rect2i(14, 0, 4, 4)])
	assert_int(pieces[0].area).is_equal(32)


func test_un_ecart_regroupe_les_pieces_proches() -> void:
	# Six pixels séparent le cadre de la première pièce (0 à 8) de la seconde (14 à 18).
	var image: Image = _image(Vector2i(32, 16), [Rect2i(0, 0, 4, 4), Rect2i(4, 4, 4, 4), Rect2i(14, 0, 4, 4)])
	assert_int(SheetImporter.find_pieces(image, 6, 1).size()).is_equal(2)
	var merged: Array[SheetPiece] = SheetImporter.find_pieces(image, 7, 1)
	assert_array(_rects(merged)).is_equal([Rect2i(0, 0, 18, 8)])
	assert_int(merged[0].area).is_equal(48)


func test_les_poussieres_sont_ignorees() -> void:
	var image: Image = _image(Vector2i(32, 32), [Rect2i(1, 1, 8, 8), Rect2i(20, 20, 2, 2)])
	assert_array(_rects(SheetImporter.find_pieces(image, 0, 16))).is_equal([Rect2i(1, 1, 8, 8)])


func test_une_piece_n_emporte_pas_les_pixels_de_sa_voisine() -> void:
	# Un L, et un carré posé dans son cadre sans le toucher : les deux cadres se recouvrent.
	var image: Image = _image(Vector2i(32, 32), [Rect2i(0, 0, 20, 4), Rect2i(0, 4, 4, 16), Rect2i(8, 8, 10, 10)])
	var pieces: Array[SheetPiece] = SheetImporter.find_pieces(image, 0, 1)
	assert_array(_rects(pieces)).is_equal([Rect2i(0, 0, 20, 20), Rect2i(8, 8, 10, 10)])
	var pages: Array[Image] = SheetImporter.build_pages(image, pieces, SheetImporter.pack(pieces, 2, 256))
	var corner: SheetPiece = pieces[0]
	var square: SheetPiece = pieces[1]
	# Dans la page, là où le carré se trouvait dans le cadre du L : rien.
	assert_float(pages[corner.page].get_pixelv(corner.page_position + Vector2i(10, 10)).a).is_equal(0.0)
	assert_float(pages[corner.page].get_pixelv(corner.page_position + Vector2i(1, 1)).a).is_equal(1.0)
	assert_bool(pages[square.page].get_pixelv(square.page_position + Vector2i(5, 5)) == image.get_pixel(13, 13)).is_true()


func test_les_pieces_se_rangent_sans_se_chevaucher_alignees_sur_les_blocs() -> void:
	var rects: Array[Rect2i] = [Rect2i(0, 0, 30, 10), Rect2i(40, 0, 7, 25), Rect2i(0, 30, 13, 13),
			Rect2i(60, 0, 50, 3), Rect2i(20, 50, 33, 21), Rect2i(70, 40, 9, 9)]
	var pieces: Array[SheetPiece] = SheetImporter.find_pieces(_image(Vector2i(128, 96), rects), 0, 1)
	var page_sizes: Array[Vector2i] = SheetImporter.pack(pieces, 2, 64)
	assert_int(page_sizes.size()).is_greater(0)
	for page_size: Vector2i in page_sizes:
		assert_int(page_size.x % SheetImporter.BLOCK_PX).is_equal(0)
		assert_int(page_size.y % SheetImporter.BLOCK_PX).is_equal(0)
	for first: int in pieces.size():
		var a: SheetPiece = pieces[first]
		var cell_a: Rect2i = Rect2i(a.page_position, a.source_rect.size).grow(2)
		assert_int(cell_a.position.x % SheetImporter.BLOCK_PX).is_equal(0)
		assert_int(cell_a.position.y % SheetImporter.BLOCK_PX).is_equal(0)
		assert_bool(Rect2i(Vector2i.ZERO, page_sizes[a.page]).encloses(cell_a)).is_true()
		for second: int in range(first + 1, pieces.size()):
			var b: SheetPiece = pieces[second]
			if a.page == b.page:
				assert_bool(cell_a.intersects(Rect2i(b.page_position, b.source_rect.size).grow(2))).is_false()


func test_une_piece_trop_grande_pour_une_page_est_refusee() -> void:
	var pieces: Array[SheetPiece] = SheetImporter.find_pieces(_image(Vector2i(32, 32), [Rect2i(0, 0, 20, 4)]), 0, 1)
	assert_array(SheetImporter.pack(pieces, 2, 16)).is_empty()


func test_la_planche_de_laurent_donne_onze_pieces() -> void:
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(SHEET))
	var pieces: Array[SheetPiece] = SheetImporter.find_pieces(image, 0, 16)
	assert_int(pieces.size()).is_equal(11)
	# Les dalles du haut, puis la dalle grise du bas : deux pièces, à deux pixels l'une de l'autre.
	assert_bool(_rects(pieces).has(Rect2i(1, 11, 469, 472))).is_true()
	assert_bool(_rects(pieces).has(Rect2i(6, 485, 453, 513))).is_true()
