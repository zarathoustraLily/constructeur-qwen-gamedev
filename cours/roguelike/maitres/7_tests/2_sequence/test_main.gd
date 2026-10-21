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
#@ 7-9
## Les ennemis poursuivent le joueur en suivant la navigation du niveau.
#@ 8-9
## L'ennemi à distance finit par lancer une boule de feu.
#@ 9
## Chaque personnage a sa barre de santé ; un coup reçu affiche ses dégâts à l'écran.
#@ 10+
## La vague fait apparaître ses ennemis un à un, chacun avec sa barre ; un coup reçu affiche ses dégâts ;
## vaincue, elle ouvre la sortie ; la sortie atteinte, le joueur revient au départ et une vague plus nombreuse
## commence.
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
#@ 7-9


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
#@ 8-9


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
#@ 9


func test_chaque_personnage_a_sa_barre_de_sante() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	for character: String in ["Player", "MeleeEnemy", "MeleeEnemy2", "RangedEnemy"]:
		var bars := main.get_node(character).find_children("*", "HealthBar", false, false)
		assert_int(bars.size()).override_failure_message(character + " : pas de barre").is_equal(1)


func test_un_coup_recu_affiche_ses_degats() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	var enemy := main.get_node("MeleeEnemy") as Enemy
	enemy.health_component.take_damage(7.0)
	var numbers := main.get_node("DamageNumbers").find_children("*", "DamageNumber", false, false)
	assert_int(numbers.size()).is_equal(1)
	assert_str((numbers[0] as DamageNumber).label.text).is_equal("7.0")
#@ 10+


## Attend les images physiques des apparitions de toute la vague.
func _wait_for_wave(main: Node3D) -> WaveObjective:
	var wave := main.get_node("WaveObjective") as WaveObjective
	var frames := int((wave.settings.first_delay + wave.settings.interval * wave.remaining()) * 60.0) + 10
	for _frame: int in frames:
		await get_tree().physics_frame
	return wave


func test_la_vague_fait_apparaitre_ses_ennemis_chacun_avec_sa_barre() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	var wave := main.get_node("WaveObjective") as WaveObjective
	assert_int(wave.remaining()).is_equal(wave.settings.enemy_count(1))
	assert_array(wave.find_children("*", "Enemy", false, false)).is_empty()
	await _wait_for_wave(main)
	var enemies := wave.find_children("*", "Enemy", false, false)
	assert_int(enemies.size()).is_equal(wave.settings.enemy_count(1))
	for enemy: Node in enemies:
		assert_int(enemy.find_children("*", "HealthBar", false, false).size()).is_equal(1)
	enemies[0].get("health_component").call(&"take_damage", 7.0)
	# Le dernier chiffre posé : le joueur a pu être touché pendant l'attente.
	var numbers := main.get_node("DamageNumbers").find_children("*", "DamageNumber", false, false)
	assert_str((numbers[-1] as DamageNumber).label.text).is_equal("7.0")


func test_vaincue_la_vague_ouvre_la_sortie_atteinte_une_vague_plus_nombreuse_commence() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	var wave := await _wait_for_wave(main)
	var exit := main.get_node("ExitPoint") as ExitPoint
	assert_bool(exit.locked).is_true()
	for enemy: Node in wave.find_children("*", "Enemy", false, false):
		var health := enemy.get("health_component") as HealthComponent
		health.take_damage(health.max_health)
	assert_bool(exit.locked).is_false()
	assert_bool(exit.visible).is_true()
	var player := main.get_node("Player") as Player
	player.global_position = exit.global_position + Vector3.UP
	for _frame: int in 3:
		await get_tree().physics_frame
	assert_int(main.get("level_rank")).is_equal(2)
	assert_vector(player.global_position).is_not_equal(exit.global_position + Vector3.UP)
	assert_int(wave.remaining()).is_equal(wave.settings.enemy_count(2))
	assert_int(wave.settings.enemy_count(2)).is_greater(wave.settings.enemy_count(1))
#@ all
