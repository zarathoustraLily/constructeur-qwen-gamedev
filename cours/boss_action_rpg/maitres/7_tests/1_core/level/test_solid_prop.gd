extends GdUnitTestSuite
## Règles d'un objet du décor agrandi : il arrête ce qui vient de dehors, sur la couche du décor ; sa boîte prend sa
## taille agrandie ; son corps n'hérite pas de son échelle ; il suit sa rotation.


func _prop(scale_factor: Vector3, turn: float = 0.0) -> SolidProp:
	var mesh: BoxMesh = BoxMesh.new()
	var prop: SolidProp = auto_free(SolidProp.new())
	prop.mesh = mesh
	prop.scale = scale_factor
	prop.rotation.y = turn
	add_child(prop)
	return prop


func _body(prop: SolidProp) -> StaticBody3D:
	return prop.get_child(0) as StaticBody3D


func test_elle_est_sur_la_couche_du_decor() -> void:
	assert_bool(Layers.has(_body(_prop(Vector3.ONE)).collision_layer, Layers.WORLD)).is_true()


func test_sa_boite_prend_la_taille_agrandie() -> void:
	var body: StaticBody3D = _body(_prop(Vector3(2.0, 3.0, 4.0)))
	var box: BoxShape3D = (body.get_child(0) as CollisionShape3D).shape as BoxShape3D
	assert_vector(box.size).is_equal_approx(Vector3(2.0, 3.0, 4.0), Vector3.ONE * 0.001)


func test_son_corps_n_herite_pas_de_son_echelle() -> void:
	var body: StaticBody3D = _body(_prop(Vector3(2.0, 3.0, 4.0)))
	assert_vector(body.global_basis.get_scale()).is_equal_approx(Vector3.ONE, Vector3.ONE * 0.001)


func test_il_suit_sa_rotation() -> void:
	var body: StaticBody3D = _body(_prop(Vector3.ONE * 2.0, PI / 2.0))
	assert_float(body.global_rotation.y).is_equal_approx(PI / 2.0, 0.001)
