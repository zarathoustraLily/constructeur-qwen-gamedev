extends GdUnitTestSuite
## Règles des pièces du spectre : le crâne a deux orbites creuses, avec un feu dans chacune ; les os ne bougent pas
## sous le shader, le linceul ondule et se dissout de plus en plus vers le bas ; son bas est en lambeaux ; chaque pièce
## n'est construite qu'une fois, et deux constructions donnent le même maillage.


func _sommets(part: StringName) -> PackedVector3Array:
	return SpectreBones.mesh(part).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]


func _couleurs(part: StringName) -> PackedColorArray:
	return SpectreBones.mesh(part).surface_get_arrays(0)[Mesh.ARRAY_COLOR]


## La distance au centre du crâne du sommet d'os le plus proche de la direction `d`.
func _profondeur(d: Vector3) -> float:
	var sommets: PackedVector3Array = _sommets(&"skull")
	var couleurs: PackedColorArray = _couleurs(&"skull")
	var meilleur: float = -2.0
	var distance: float = 0.0
	for i: int in sommets.size():
		if couleurs[i].b > 0.9:
			continue
		var vers: Vector3 = sommets[i] - SpectreBones.SKULL_CENTER
		if vers.normalized().dot(d) > meilleur:
			meilleur = vers.normalized().dot(d)
			distance = vers.length()
	return distance


func test_le_crane_a_deux_orbites_creuses_et_un_feu_dans_chacune() -> void:
	var front: float = _profondeur(Vector3(0.0, 0.6, -1.0).normalized())
	for side: float in [-1.0, 1.0]:
		assert_float(_profondeur(SpectreBones.eye_direction(side))).is_less(front - 0.03)
	var sommets: PackedVector3Array = _sommets(&"skull")
	var couleurs: PackedColorArray = _couleurs(&"skull")
	var feux: Array[int] = [0, 0]
	for i: int in sommets.size():
		if couleurs[i].b > 0.9:
			feux[0 if sommets[i].x < 0.0 else 1] += 1
	assert_int(feux[0]).is_greater(0)
	assert_int(feux[1]).is_greater(0)


func test_les_os_ne_bougent_pas_le_linceul_ondule_vers_le_bas() -> void:
	for part: StringName in [&"skull", &"jaw", &"upper_arm", &"forearm", &"hand_left", &"hand_right"]:
		for c: Color in _couleurs(part):
			assert_float(c.r).is_equal(0.0)
	var sommets: PackedVector3Array = _sommets(&"shroud")
	var couleurs: PackedColorArray = _couleurs(&"shroud")
	var haut: int = 0
	var bas: int = 0
	for i: int in sommets.size():
		if sommets[i].y > sommets[haut].y:
			haut = i
		if sommets[i].y < sommets[bas].y:
			bas = i
	assert_float(couleurs[haut].r).is_less(0.01)
	assert_float(couleurs[bas].r).is_greater(0.8)
	assert_float(couleurs[bas].g).is_greater(0.6)


func test_le_bas_du_linceul_est_en_lambeaux() -> void:
	var sommets: PackedVector3Array = _sommets(&"shroud")
	var premier: int = (SpectreBones.SHROUD_ROWS - 1) * SpectreBones.SHROUD_COLUMNS
	var plus_haut: float = -INF
	var plus_bas: float = INF
	for k: int in SpectreBones.SHROUD_COLUMNS:
		plus_haut = maxf(plus_haut, sommets[premier + k].y)
		plus_bas = minf(plus_bas, sommets[premier + k].y)
	assert_float(plus_haut - plus_bas).is_greater(0.3)


func test_chaque_piece_n_est_construite_qu_une_fois_et_toujours_la_meme() -> void:
	for part: StringName in SpectreBones.PARTS:
		assert_object(SpectreBones.mesh(part)).is_same(SpectreBones.mesh(part))
	var neuf: PackedVector3Array = SpectreBones.build(&"shroud").surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_bool(neuf == _sommets(&"shroud")).is_true()
