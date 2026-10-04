extends GdUnitTestSuite
## Règles du joueur : saut simple puis double, gravité, pièces, déplacement selon la caméra.


func after_test() -> void:
	for action in ["move_left", "move_right", "move_forward", "move_back", "jump"]:
		Input.action_release(action)


func _joueur() -> CharacterBody3D:
	var p: CharacterBody3D = auto_free(load("res://objects/player.tscn").instantiate())
	add_child(p)
	return p


func test_premier_saut() -> void:
	var p := _joueur()
	p.jump()
	assert_float(float(p.gravity)).is_equal(-7.0)
	assert_bool(p.jump_single).is_false()
	assert_bool(p.jump_double).is_true()
	assert_vector(p.model.scale).is_equal(Vector3(0.5, 1.5, 0.5))


func test_double_saut_puis_plus_rien() -> void:
	var p := _joueur()
	p.jump()
	p.jump()
	assert_bool(p.jump_single).is_false()
	assert_bool(p.jump_double).is_false()


func test_force_de_saut_reglable() -> void:
	var p := _joueur()
	p.jump_strength = 12
	p.jump()
	assert_float(float(p.gravity)).is_equal(-12.0)


func test_gravite_s_accumule_en_l_air() -> void:
	var p := _joueur()
	p.handle_gravity(0.1)
	assert_float(float(p.gravity)).is_equal_approx(2.5, 0.0001)
	p.handle_gravity(0.1)
	assert_float(float(p.gravity)).is_equal_approx(5.0, 0.0001)


func test_piece_ramassee_compte_et_previent() -> void:
	var p := _joueur()
	var recus := []
	p.coin_collected.connect(func(n) -> void: recus.append(n))
	p.collect_coin()
	p.collect_coin()
	assert_int(p.coins).is_equal(2)
	assert_array(recus).is_equal([1, 2])


func test_deplacement_vers_la_droite() -> void:
	var p := _joueur()
	Input.action_press("move_right")
	p.handle_controls(0.1)
	assert_vector(p.movement_velocity).is_equal_approx(Vector3(25, 0, 0), Vector3(0.001, 0.001, 0.001))


func test_deplacement_diagonal_normalise() -> void:
	var p := _joueur()
	Input.action_press("move_right")
	Input.action_press("move_back")
	p.handle_controls(0.1)
	assert_float(p.movement_velocity.length()).is_equal_approx(25.0, 0.001)


func test_deplacement_suit_la_camera() -> void:
	var p := _joueur()
	var vue: Node3D = auto_free(Node3D.new())
	vue.rotation.y = PI / 2
	p.view = vue
	Input.action_press("move_forward")
	p.handle_controls(0.1)
	# Avant (-z) tourné de 90° autour de Y : vers -x.
	assert_vector(p.movement_velocity).is_equal_approx(Vector3(-25, 0, 0), Vector3(0.001, 0.001, 0.001))


func test_sans_entree_pas_de_mouvement() -> void:
	var p := _joueur()
	p.handle_controls(0.1)
	assert_vector(p.movement_velocity).is_equal(Vector3.ZERO)


func test_animation_de_saut_en_l_air() -> void:
	var p := _joueur()
	p.handle_effects(0.016)
	assert_str(p.animation.current_animation).is_equal("jump")
	assert_bool(p.particles_trail.emitting).is_false()
	assert_bool(p.sound_footsteps.stream_paused).is_true()
