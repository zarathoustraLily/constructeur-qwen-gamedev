extends GdUnitTestSuite
#@ 1
## Règles de la scène principale : elle montre à chaque image les commandes que l'adaptateur a lues ; la flèche
## de visée suit la marche quand on ne vise pas, tournée comme la caméra ; la vibration du coup est réglée.
#@ 2-3
## Règles de la scène principale : elle montre les commandes que le joueur a lues ; le joueur se tient sur
## l'estrade ; la vibration du coup est réglée.
#@ 4-5
## Règles de la scène principale : elle montre les commandes que le joueur a lues ; le joueur se tient sur le
## sol du niveau ; tombé sous la limite du monde, il revient à son point de départ et sa caméra tremble ; la
## vibration du coup est réglée.
#@ 6+
## Règles de la scène principale : elle montre les commandes que le joueur a lues ; le joueur se tient sur le
## sol du niveau ; tombé sous la limite du monde, il est vaincu, puis revient à son point de départ, visible,
## avec toute sa santé, et sa caméra tremble ; la vibration du coup est réglée.
#@ 7+
## Les ennemis poursuivent le joueur en suivant la navigation du niveau.
#@ 8+
## L'ennemi à distance finit par lancer une boule de feu.
#@ 4+
#@ all

const MAIN := preload("res://2_sequence/main.tscn")


func after_test() -> void:
	Input.action_release("move_right")


## Trois images : le signal physics_frame part avant que les nœuds ne jouent leur image ; à la troisième, la
## lecture des commandes, puis leur affichage, ont eu lieu.
func _frames() -> void:
	for _frame: int in 3:
		await get_tree().physics_frame


func test_la_scene_montre_les_commandes_lues() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	Input.action_press("move_right")
	await _frames()
	assert_float((main.get_node("InputDisplay/Panel/Rows/MoveX") as ProgressBar).value).is_equal_approx(1.0, 0.001)
#@ 1


func test_sans_visee_la_fleche_suit_la_marche_tournee_comme_la_camera() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	# Un bouton de manette : la visée passe au stick droit, au repos ; la flèche suit alors la marche.
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_X
	button.pressed = true
	Input.parse_input_event(button)
	Input.flush_buffered_events()
	Input.action_press("move_right")
	await _frames()
	var camera := main.get_node("Hero/CameraRoot/Camera3D") as Camera3D
	var expected := Vector3.RIGHT.rotated(Vector3.UP, camera.global_rotation.y)
	var pivot := main.get_node("Hero/AimPivot") as Node3D
	assert_bool(pivot.visible).is_true()
	assert_vector(-pivot.global_basis.z).is_equal_approx(expected, Vector3.ONE * 0.01)
#@ 2-3


func test_le_joueur_se_tient_sur_l_estrade() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	for _frame: int in 30:
		await get_tree().physics_frame
	var player := main.get_node("Player") as Player
	assert_bool(player.is_on_floor()).is_true()
	# Le haut de l'estrade est à 1 m ; le centre du joueur, 1 m au-dessus de ses pieds.
	assert_float(player.global_position.y).is_equal_approx(2.0, 0.05)
#@ 4+


func test_le_joueur_se_tient_sur_le_sol_du_niveau() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	for _frame: int in 30:
		await get_tree().physics_frame
	var player := main.get_node("Player") as Player
	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.global_position.y).is_between(0.5, 1.5)

#@ 4-5


func test_tombe_sous_la_limite_le_joueur_revient_au_depart_et_la_camera_tremble() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	var player := main.get_node("Player") as Player
	var start := player.global_position
	await _frames()
	player.global_position = Vector3(0.0, -6.0, 0.0)
	await _frames()
	assert_vector(player.global_position).is_equal_approx(start, Vector3.ONE * 0.2)
	assert_float(player.camera.trauma).is_greater(0.0)
#@ 6+


func test_vaincu_le_joueur_revient_au_depart_visible_avec_toute_sa_sante() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	var player := main.get_node("Player") as Player
	var start := player.global_position
	var defeats: Array[int] = [0]
	player.health_component.defeated.connect(func() -> void: defeats[0] += 1)
	await _frames()
	player.global_position = Vector3(0.0, -6.0, 0.0)
	await _frames()
	assert_int(defeats[0]).is_equal(1)
	assert_vector(player.global_position).is_equal_approx(start, Vector3.ONE * 0.2)
	assert_bool(player.visible).is_true()
	assert_float(player.health_component.current_health).is_equal(player.health_component.max_health)
	assert_float(player.camera.trauma).is_greater(0.0)
#@ all


func test_la_vibration_du_coup_est_reglee() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	var rumble: Rumble = main.get("attack_rumble")
	assert_object(rumble).is_not_null()
	assert_float(rumble.duration).is_greater(0.0)
	assert_float(maxf(rumble.weak_magnitude, rumble.strong_magnitude)).is_greater(0.0)
#@ 7+


func test_les_ennemis_poursuivent_le_joueur() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	await _frames()
	var enemy := main.get_node("MeleeEnemy") as Enemy
	var start_distance := enemy.distance_to_target()
	for _frame: int in 60:
		await get_tree().physics_frame
	assert_float(enemy.distance_to_target()).is_less(start_distance - 1.0)
#@ all
#@ 8+


func test_l_ennemi_a_distance_finit_par_lancer_une_boule_de_feu() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	var ranged := main.get_node("RangedEnemy") as RangedEnemy
	var shots: Array[int] = [0]
	ranged.attack_bone.ranged_attack.connect(func() -> void: shots[0] += 1)
	for _frame: int in 600:
		await get_tree().physics_frame
		if shots[0] > 0:
			break
	assert_int(shots[0]).is_greater(0)
#@ all

