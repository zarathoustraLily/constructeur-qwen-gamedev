extends GdUnitTestSuite
## Règles de l'ennemi : patrouille, détection, poursuite, défaite.

const SCENE_GHOST := "res://scenes/ghost.tscn"


func _nouveau_ghost(position: Vector2 = Vector2.ZERO) -> Ghost:
	var ghost: Ghost = auto_free(load(SCENE_GHOST).instantiate())
	ghost.position = position
	add_child(ghost)
	ghost.set_physics_process(false)
	return ghost


func _cible(position: Vector2) -> Node2D:
	var cible: Node2D = auto_free(Node2D.new())
	cible.position = position
	add_child(cible)
	return cible


func test_patrouille_sans_cible() -> void:
	var ghost := _nouveau_ghost()
	assert_int(ghost.update_state()).is_equal(Ghost.State.PATROL)


func test_patrouille_si_cible_lointaine() -> void:
	var ghost := _nouveau_ghost()
	ghost.target = _cible(Vector2(151, 0))
	assert_int(ghost.update_state()).is_equal(Ghost.State.PATROL)


func test_poursuite_au_rayon_exact() -> void:
	var ghost := _nouveau_ghost()
	ghost.target = _cible(Vector2(150, 0))
	assert_int(ghost.update_state()).is_equal(Ghost.State.CHASE)


func test_vitesse_de_poursuite_vers_la_cible() -> void:
	var ghost := _nouveau_ghost()
	ghost.target = _cible(Vector2(0, 100))
	ghost.update_state()
	assert_vector(ghost.compute_velocity()).is_equal(Vector2(0, 120))


func test_patrouille_fait_demi_tour() -> void:
	var ghost := _nouveau_ghost(Vector2(10, 0))
	assert_vector(ghost.compute_velocity()).is_equal(Vector2(60, 0))
	ghost.position = Vector2(74, 0)
	assert_vector(ghost.compute_velocity()).is_equal(Vector2(-60, 0))
	ghost.position = Vector2(-54, 0)
	assert_vector(ghost.compute_velocity()).is_equal(Vector2(60, 0))


func test_mort_emet_defeated() -> void:
	var ghost := _nouveau_ghost()
	var defaites := [0]
	ghost.defeated.connect(func() -> void: defaites[0] += 1)
	ghost.health.take_damage(2)
	assert_int(defaites[0]).is_equal(1)
