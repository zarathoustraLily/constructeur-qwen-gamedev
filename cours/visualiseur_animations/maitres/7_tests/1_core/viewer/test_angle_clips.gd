extends GdUnitTestSuite
## Un clip « <base>_angle_<degrés> » ne sert que sous son angle : on prend la variante la plus proche de la caméra,
## en tournant par 360 (350 est près de 0), le plus petit angle à égalité ; un clip sans angle sert partout, un numéro
## de coup (attaque_2) n'est pas un angle ; un nom inconnu ne donne rien.

const CLIPS: Array[String] = ["course", "salut_angle_0", "salut_angle_90", "salut_angle_180", "salut_angle_270",
		"garde_angle_45", "attaque_2"]


func test_le_nom_de_base_et_l_angle_d_un_clip() -> void:
	assert_str(AngleClips.base_of("salut_angle_90")).is_equal("salut")
	assert_int(AngleClips.angle_of("salut_angle_90")).is_equal(90)
	assert_str(AngleClips.base_of("course")).is_equal("course")
	assert_int(AngleClips.angle_of("course")).is_equal(-1)
	assert_str(AngleClips.base_of("attaque_2")).is_equal("attaque_2")
	assert_str(AngleClips.base_of("vol_angle_haut")).is_equal("vol_angle_haut")


func test_les_bases_et_les_angles() -> void:
	assert_array(AngleClips.bases(CLIPS)).is_equal(["attaque_2", "course", "garde", "salut"])
	assert_array(AngleClips.angles(CLIPS, "salut")).is_equal([0, 90, 180, 270])
	assert_array(AngleClips.angles(CLIPS, "course")).is_empty()


func test_la_variante_la_plus_proche_de_la_camera() -> void:
	assert_str(AngleClips.pick(CLIPS, "salut", 100.0)).is_equal("salut_angle_90")
	assert_str(AngleClips.pick(CLIPS, "salut", 200.0)).is_equal("salut_angle_180")
	assert_str(AngleClips.pick(CLIPS, "salut", 350.0)).is_equal("salut_angle_0")
	assert_str(AngleClips.pick(CLIPS, "salut", -100.0)).is_equal("salut_angle_270")


func test_a_egalite_le_plus_petit_angle() -> void:
	assert_str(AngleClips.pick(CLIPS, "salut", 45.0)).is_equal("salut_angle_0")


func test_une_seule_variante_sert_sous_tous_les_angles() -> void:
	assert_str(AngleClips.pick(CLIPS, "garde", 260.0)).is_equal("garde_angle_45")


func test_un_clip_sans_angle_et_un_nom_inconnu() -> void:
	assert_str(AngleClips.pick(CLIPS, "course", 123.0)).is_equal("course")
	assert_str(AngleClips.pick(CLIPS, "vol", 0.0)).is_empty()
