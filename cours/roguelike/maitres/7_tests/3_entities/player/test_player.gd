extends GdUnitTestSuite
## Règles du joueur : sans commande il reste sur place ; il marche dans la direction voulue, tournée comme sa
## caméra, à la vitesse de ses réglages, et un stick à moitié le fait marcher à moitié vitesse ; son modèle
## se tourne vers sa marche ; sans sol il tombe, puis reprend sa course en touchant le sol.
#@ 3+
## Animation : il apparaît en sortant du sol ; en marche l'animation passe à la course, à l'arrêt au repos ;
## ses pieds font entendre ses pas ; il tient son épée dans la main droite.
#@ 5+
## Esquive : à l'arrêt, pas d'esquive ; l'esquive le lance vite dans la direction de la marche, le temps de sa
## durée, puis la course reprend ; elle est signalée avec sa direction ; la recharge empêche une seconde
## esquive aussitôt, puis la permet.
#@ 6+
## Combat : un coup lance la taille ; sans autre demande, la course reprend à la fin de l'animation ; un coup
## demandé pendant la taille enchaîne l'estoc, puis le tourbillon ; l'esquive interrompt la taille, pas le
## tourbillon ; l'épée blesse et repousse une cible devant le joueur ; la visée prend la visée, à défaut la
## marche ; repoussé, le joueur suit son recul.
#@ all

const PLAYER := preload("res://3_entities/player/player.tscn")

var _player: Player


func before_test() -> void:
	var ground: StaticBody3D = auto_free(StaticBody3D.new())
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child(ground)
	_player = auto_free(PLAYER.instantiate())
	# Pas d'adaptateur : le test écrit lui-même les commandes.
	_player.input = null
	_player.position = Vector3(0.0, 1.0, 0.0)
	add_child(_player)


func _frames(count: int) -> void:
	for _frame: int in count:
		await get_tree().physics_frame


func _state() -> String:
	return str((_player.get_node("StateMachine") as StateMachine).state.name)


func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)


func test_sans_commande_le_joueur_reste_sur_place() -> void:
	await _frames(30)
	assert_vector(_flat(_player.global_position)).is_equal_approx(Vector3.ZERO, Vector3.ONE * 0.01)
	assert_str(_state()).is_equal("PlayerRun")


func test_il_marche_dans_la_direction_voulue_tournee_comme_la_camera() -> void:
	await _frames(10)
	var start := _player.global_position
	_player.commands.move = Vector2.RIGHT
	await _frames(60)
	var moved := _flat(_player.global_position - start)
	var expected := Vector3.RIGHT.rotated(Vector3.UP, _player.camera.global_rotation.y)
	assert_vector(moved.normalized()).is_equal_approx(expected, Vector3.ONE * 0.01)
	# Une seconde de marche : la vitesse des réglages, à une image près.
	assert_float(moved.length()).is_equal_approx(_player.settings.movement_speed, _player.settings.movement_speed / 30.0)


func test_un_stick_a_moitie_fait_marcher_a_moitie_vitesse() -> void:
	await _frames(10)
	var start := _player.global_position
	_player.commands.move = Vector2(0.0, -0.5)
	await _frames(60)
	var speed := _player.settings.movement_speed
	assert_float(_flat(_player.global_position - start).length()).is_equal_approx(speed * 0.5, speed / 30.0)


func test_le_modele_se_tourne_vers_la_marche() -> void:
	_player.commands.move = Vector2.LEFT
	await _frames(60)
	var expected := Vector3.LEFT.rotated(Vector3.UP, _player.camera.global_rotation.y)
	# Le modèle regarde vers son +Z (look_at avec use_model_front).
	assert_vector(_player.model.global_basis.z.normalized()).is_equal_approx(expected, Vector3.ONE * 0.02)


func test_sans_sol_il_tombe_puis_reprend_sa_course_au_sol() -> void:
	_player.global_position = Vector3(0.0, 4.0, 0.0)
	await _frames(3)
	assert_str(_state()).is_equal("PlayerFall")
	await _frames(60)
	assert_str(_state()).is_equal("PlayerRun")
	assert_bool(_player.is_on_floor()).is_true()
	assert_float(_player.global_position.y).is_equal_approx(1.0, 0.05)


func test_les_reglages_sont_poses() -> void:
	assert_object(_player.settings).is_not_null()
	assert_float(_player.settings.movement_speed).is_greater(0.0)
	assert_float(_player.settings.turn_rate).is_greater(0.0)
#@ 3+


func test_il_apparait_en_sortant_du_sol() -> void:
	await _frames(2)
	assert_str(str(_player.animation_tree.current_state())).is_equal("Spawn")


func test_en_marche_l_animation_passe_a_la_course_puis_au_repos() -> void:
	var tree := _player.animation_tree
	_player.commands.move = Vector2.RIGHT
	await _frames(40)
	assert_float(tree.get(tree.blend_parameter) as float).is_greater(0.9)
	_player.commands.move = Vector2.ZERO
	await _frames(40)
	assert_float(tree.get(tree.blend_parameter) as float).is_less(-0.9)


func test_ses_pieds_font_entendre_ses_pas() -> void:
	var feet := _player.model.find_children("*", "FootBone", true, false)
	assert_int(feet.size()).is_equal(2)
	var steps: Array[String] = []
	for foot: Node in feet:
		var audio := foot.get_node("FootstepAudio") as AudioStreamPlayer3D
		assert_bool((foot as FootBone).footstep.is_connected(audio.play)).is_true()
		(foot as FootBone).footstep.connect(func() -> void: steps.append(str(foot.name)))
	_player.animation_tree.change_immediate(&"WalkSpace")
	_player.commands.move = Vector2.RIGHT
	await _frames(120)
	# La course fait poser chaque pied, tour à tour.
	assert_array(steps).contains(["RightFootBone", "LeftFootBone"])


func test_il_tient_son_epee_dans_la_main_droite() -> void:
	var slots := _player.model.find_children("*", "WeaponSlot", true, false)
	assert_int(slots.size()).is_equal(1)
	assert_str((slots[0] as WeaponSlot).bone_name).is_equal("hand.r")
	assert_object(slots[0].get_node_or_null("LazerSword")).is_not_null()
#@ all
#@ 5+


## Demande une esquive pendant une image, comme l'adaptateur (« vient d'être enfoncée »).
func _dash() -> void:
	_player.commands.dash = true
	await get_tree().physics_frame
	_player.commands.dash = false


func test_a_l_arret_il_ne_peut_pas_esquiver() -> void:
	await _frames(10)
	assert_bool(_player.can_dash()).is_false()
	await _dash()
	await _frames(2)
	assert_str(_state()).is_equal("PlayerRun")


func test_l_esquive_le_lance_vite_dans_la_direction_de_la_marche_puis_la_course_reprend() -> void:
	_player.commands.move = Vector2.RIGHT
	await _frames(10)
	var start := _player.global_position
	await _dash()
	await _frames(2)
	assert_str(_state()).is_equal("PlayerDash")
	await _frames(12)
	assert_str(_state()).is_equal("PlayerRun")
	var expected := Vector3.RIGHT.rotated(Vector3.UP, _player.camera.global_rotation.y)
	var moved := _flat(_player.global_position - start)
	# Sans esquive, 15 images de marche feraient 2 m ; l'esquive en ajoute 5 (50 m/s pendant 0,1 s).
	assert_float(moved.dot(expected)).is_greater(_player.settings.dash_speed * _player.settings.dash_duration)


func test_l_esquive_est_signalee_avec_sa_direction() -> void:
	var directions: Array[Vector3] = []
	_player.dashed.connect(func(direction: Vector3) -> void: directions.append(direction))
	_player.commands.move = Vector2(0.0, 0.5)
	await _frames(10)
	await _dash()
	await _frames(2)
	assert_int(directions.size()).is_equal(1)
	var expected := Vector3.BACK.rotated(Vector3.UP, _player.camera.global_rotation.y)
	# Un stick à moitié : la direction de l'esquive garde une longueur de 1.
	assert_vector(directions[0]).is_equal_approx(expected, Vector3.ONE * 0.001)


func test_la_recharge_empeche_une_seconde_esquive_aussitot_puis_la_permet() -> void:
	_player.commands.move = Vector2.RIGHT
	await _frames(10)
	await _dash()
	await _frames(10)
	assert_bool(_player.can_dash()).is_false()
	await _frames(int(_player.settings.dash_cooldown * 60.0))
	assert_bool(_player.can_dash()).is_true()
#@ all
#@ 6+


## Demande un coup pendant une image.
func _attack() -> void:
	_player.commands.attack = true
	await get_tree().physics_frame
	_player.commands.attack = false


## Une cible sur la couche des ennemis, avec santé et recul, à `distance` m devant le modèle du joueur.
func _target(distance: float) -> CharacterBody3D:
	var target: CharacterBody3D = auto_free(CharacterBody3D.new())
	target.collision_layer = 2
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	shape.shape = capsule
	target.add_child(shape)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	target.add_child(health)
	var knockback := KnockbackComponent.new()
	knockback.name = "KnockbackComponent"
	target.add_child(knockback)
	add_child(target)
	target.global_position = _player.global_position + _player.model.global_basis.z.normalized() * distance
	return target


func test_un_coup_lance_la_taille_puis_la_course_reprend() -> void:
	await _frames(10)
	await _attack()
	await _frames(2)
	assert_str(_state()).is_equal("PlayerAttack")
	assert_str(str(_player.animation_tree.current_state())).is_equal("SlashAttack")
	await _frames(90)
	assert_str(_state()).is_equal("PlayerRun")


func test_un_coup_demande_pendant_la_taille_enchaine_l_estoc_puis_le_tourbillon() -> void:
	await _frames(10)
	var states: Array[String] = []
	(_player.get_node("StateMachine") as StateMachine).state_changed.connect(
		func(_from: StringName, to: StringName) -> void: states.append(str(to)))
	await _attack()
	await _frames(10)
	await _attack()
	await _frames(40)
	await _attack()
	# Le tourbillon dure 2,4 s, joué une fois et demie plus vite : 96 images.
	await _frames(120)
	assert_array(states).contains_exactly(["PlayerAttack", "PlayerAttack2", "PlayerAttack3", "PlayerRun"])


func test_l_esquive_interrompt_la_taille_mais_pas_le_tourbillon() -> void:
	_player.commands.move = Vector2.RIGHT
	await _frames(10)
	await _attack()
	await _frames(3)
	await _dash()
	await _frames(2)
	assert_str(_state()).is_equal("PlayerDash")
	await _frames(30)
	var machine := _player.get_node("StateMachine") as StateMachine
	machine.transition_to(&"PlayerAttack3")
	await _frames(3)
	await _dash()
	await _frames(2)
	assert_str(_state()).is_equal("PlayerAttack3")


func test_l_epee_blesse_et_repousse_une_cible_devant_le_joueur() -> void:
	await _frames(10)
	var target := _target(1.5)
	var health := target.get_node("HealthComponent") as HealthComponent
	await _attack()
	await _frames(60)
	assert_float(health.current_health).is_less(health.max_health)
	var knockback := target.get_node("KnockbackComponent") as KnockbackComponent
	assert_float(knockback.magnitude.length() + health.max_health - health.current_health).is_greater(0.0)


func test_la_visee_prend_la_visee_a_defaut_la_marche() -> void:
	var yaw := _player.camera.global_rotation.y
	_player.commands.aim = Vector2(0.0, -3.0)
	_player.commands.move = Vector2.RIGHT
	assert_vector(_player.get_aim_direction()).is_equal_approx(Vector3.FORWARD.rotated(Vector3.UP, yaw), Vector3.ONE * 0.001)
	_player.commands.aim = Vector2.ZERO
	assert_vector(_player.get_aim_direction()).is_equal_approx(Vector3.RIGHT.rotated(Vector3.UP, yaw), Vector3.ONE * 0.001)


func test_repousse_le_joueur_suit_son_recul() -> void:
	await _frames(10)
	var start := _player.global_position
	_player.knockback_component.add_knockback(Vector3(20.0, 0.0, 0.0))
	await _frames(10)
	assert_float(_player.global_position.x - start.x).is_greater(1.0)
#@ all
