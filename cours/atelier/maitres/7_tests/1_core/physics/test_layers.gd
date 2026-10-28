extends GdUnitTestSuite
## Règles des couches de collision : la couche n donne le bit n - 1 ; un masque réunit des couches ; on sait si un
## masque regarde une couche ; les noms des couches sont ceux de project.godot.


func test_la_couche_n_donne_le_bit_n_moins_un() -> void:
	assert_int(Layers.bit(1)).is_equal(1)
	assert_int(Layers.bit(Layers.PLAYER)).is_equal(2)
	assert_int(Layers.bit(4)).is_equal(8)
	assert_int(Layers.bit(32)).is_equal(1 << 31)


func test_un_masque_reunit_des_couches() -> void:
	assert_int(Layers.mask([Layers.WORLD, Layers.ENEMY])).is_equal(0b101)
	assert_int(Layers.mask([])).is_equal(0)


func test_on_sait_si_un_masque_regarde_une_couche() -> void:
	var value: int = Layers.mask([Layers.WORLD, Layers.HITBOX])
	assert_bool(Layers.has(value, Layers.WORLD)).is_true()
	assert_bool(Layers.has(value, Layers.HITBOX)).is_true()
	assert_bool(Layers.has(value, Layers.PLAYER)).is_false()


func test_les_noms_sont_ceux_du_projet() -> void:
	assert_str(ProjectSettings.get_setting("layer_names/3d_physics/layer_%d" % Layers.WORLD)).is_equal("monde")
	assert_str(ProjectSettings.get_setting("layer_names/3d_physics/layer_%d" % Layers.PLAYER)).is_equal("joueur")
