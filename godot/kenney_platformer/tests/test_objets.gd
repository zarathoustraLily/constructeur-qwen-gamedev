extends GdUnitTestSuite
## Pièce, brique et plateforme qui tombe.


class FauxJoueur extends Node3D:
	var pieces := 0

	func collect_coin() -> void:
		pieces += 1


func _instance(chemin: String) -> Node3D:
	var n: Node3D = auto_free(load(chemin).instantiate())
	add_child(n)
	return n


func test_piece_ramassee_une_seule_fois() -> void:
	var piece := _instance("res://objects/coin.tscn")
	var joueur: FauxJoueur = auto_free(FauxJoueur.new())
	piece.body_entered.emit(joueur)
	piece.body_entered.emit(joueur)
	assert_int(joueur.pieces).is_equal(1)
	assert_bool(piece.grabbed).is_true()
	assert_bool(piece.get_node("Particles").emitting).is_false()


func test_piece_ignore_les_autres_corps() -> void:
	var piece := _instance("res://objects/coin.tscn")
	var caillou: Node3D = auto_free(Node3D.new())
	piece.body_entered.emit(caillou)
	assert_bool(piece.grabbed).is_false()


func test_piece_tourne_et_flotte() -> void:
	var piece := _instance("res://objects/coin.tscn")
	var y0 := piece.position.y
	piece._process(0.1)
	assert_float(piece.rotation.y).is_equal_approx(0.2, 0.0001)
	assert_float(piece.position.y - y0).is_equal_approx(0.1, 0.0001)
	assert_float(piece.time).is_equal_approx(0.1, 0.0001)


func test_brique_explose_par_dessous() -> void:
	var brique := _instance("res://objects/brick.tscn")
	var joueur: Node3D = auto_free(Node3D.new())
	joueur.add_to_group("player")
	brique.get_node("BottomDetector").body_entered.emit(joueur)
	assert_bool(brique.exploded).is_true()
	assert_bool(brique.mesh.visible).is_false()
	assert_bool(brique.get_node("CollisionShape3D").disabled).is_true()


func test_brique_insensible_aux_autres_corps() -> void:
	var brique := _instance("res://objects/brick.tscn")
	var caillou: Node3D = auto_free(Node3D.new())
	brique.get_node("BottomDetector").body_entered.emit(caillou)
	assert_bool(brique.exploded).is_false()
	assert_bool(brique.mesh.visible).is_true()


func test_brique_explose_une_seule_fois() -> void:
	var brique := _instance("res://objects/brick.tscn")
	brique.explode()
	brique.mesh.show()
	brique.explode()
	assert_bool(brique.mesh.visible).is_true()


func test_plateforme_tombe_quand_on_monte_dessus() -> void:
	var plateforme := _instance("res://objects/platform_falling.tscn")
	var joueur: Node3D = auto_free(Node3D.new())
	plateforme.get_node("Area3D").body_entered.emit(joueur)
	assert_bool(plateforme.falling).is_true()
	assert_vector(plateforme.scale).is_equal(Vector3(1.25, 1, 1.25))


func test_plateforme_accelere_en_tombant() -> void:
	var plateforme := _instance("res://objects/platform_falling.tscn")
	plateforme.falling = true
	plateforme._physics_process(0.1)
	assert_float(plateforme.fall_velocity).is_equal_approx(1.5, 0.0001)
	assert_float(plateforme.position.y).is_equal_approx(-0.15, 0.0001)
	plateforme._physics_process(0.1)
	assert_float(plateforme.fall_velocity).is_equal_approx(3.0, 0.0001)
	assert_float(plateforme.position.y).is_equal_approx(-0.45, 0.0001)


func test_plateforme_immobile_sans_joueur() -> void:
	var plateforme := _instance("res://objects/platform_falling.tscn")
	plateforme._physics_process(0.1)
	assert_float(plateforme.fall_velocity).is_equal(0.0)
	assert_float(plateforme.position.y).is_equal(0.0)


func test_plateforme_disparait_tout_en_bas() -> void:
	var plateforme := _instance("res://objects/platform_falling.tscn")
	plateforme.position.y = -10.5
	plateforme._physics_process(0.01)
	assert_bool(plateforme.is_queued_for_deletion()).is_true()


func test_nuage_flotte() -> void:
	var nuage := _instance("res://objects/cloud.tscn")
	nuage.random_velocity = 2.0
	nuage.random_time = 1.0
	nuage.time = 0.0
	var y0 := nuage.position.y
	nuage._process(0.5)
	assert_float(nuage.position.y - y0).is_equal_approx(1.0, 0.0001)
	assert_float(nuage.time).is_equal_approx(0.5, 0.0001)
