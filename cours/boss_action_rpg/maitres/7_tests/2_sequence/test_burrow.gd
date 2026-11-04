extends GdUnitTestSuite
## Règles du Terrier : Bobine se pose sur le plancher, et sa caméra est active ; aucun rayon ne sort des salles ; à pleine
## course contre chaque mur, elle reste dedans ; elle passe de la chambre à l'atelier par le couloir ; près de la bougie,
## l'invite la nomme ; le bouton Y de la manette la souffle, la touche F la rallume ; la qualité basse s'applique sans lune ni
## brume au sol.
#@ 28+
## Elle arrive avec une baguette, qui ne tire pas. Quatre armes attendent sur leurs socles ; le bouton Y en prend une : elle
## est en main, l'interface la nomme, et le socle se vide. Un tir sur une boîte de conserve l'affiche.
#@ all

const BURROW := preload("res://2_sequence/burrow.tscn")
## Un point de chaque salle.
const ROOMS: Array[Vector3] = [Vector3(0.0, 1.0, 3.0), Vector3(0.0, 1.0, -10.0), Vector3(0.0, 1.0, -19.0)]


func _burrow() -> Level:
	var level: Level = auto_free(BURROW.instantiate())
	add_child(level)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return level


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func _candle(level: Level) -> Candle:
	return level.get_node("Decor/Candle") as Candle


## Pose Bobine tout près de la bougie, et laisse sa main la voir.
func _beside_candle(level: Level) -> void:
	await _frames(3)
	level.hero.global_position = _candle(level).global_position + Vector3(1.4, 0.0, 0.0)
	await _frames(4)


func _press(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await _frames(2)


func _gamepad_y(pressed: bool) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_Y
	event.pressed = pressed
	return event


func _key_f(pressed: bool) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = KEY_F
	event.pressed = pressed
	return event


func test_bobine_se_pose_sur_le_plancher_et_sa_camera_est_active() -> void:
	var level: Level = _burrow()
	await _frames(30)
	assert_bool(level.hero.is_on_floor()).is_true()
	assert_float(absf(level.hero.global_position.y)).is_less(0.1)
	assert_that(level.get_viewport().get_camera_3d()).is_same(level.get_node("OrbitCamera/Arm/Camera"))


func test_aucun_rayon_ne_sort_des_salles() -> void:
	var level: Level = _burrow()
	await _frames(3)
	var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state
	for room: Vector3 in ROOMS:
		for i: int in 16:
			var angle: float = TAU * i / 16.0
			for aim: Vector3 in [Vector3(cos(angle), 0.0, sin(angle)), Vector3(cos(angle), 1.0, sin(angle)).normalized()]:
				var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(room, room + aim * 80.0, Layers.bit(Layers.WORLD))
				assert_bool(space.intersect_ray(query).is_empty()).override_failure_message("sortie : %s %s" % [room, aim]).is_false()


func test_a_pleine_course_contre_chaque_mur_elle_reste_dedans() -> void:
	var level: Level = _burrow()
	level.hero.get_node("Input").free()
	await _frames(3)
	for i: int in 8:
		var angle: float = TAU * i / 8.0
		level.hero.stick = Vector2(cos(angle), sin(angle))
		level.hero.dodge_held = true
		await _frames(150)
		var at: Vector3 = level.hero.global_position
		assert_float(at.y).is_between(-0.2, 2.0)
		assert_float(at.x).is_between(-11.0, 11.0)
		assert_float(at.z).is_between(-26.5, 8.0)


func test_elle_passe_de_la_chambre_a_l_atelier_par_le_couloir() -> void:
	var level: Level = _burrow()
	level.hero.get_node("Input").free()
	await _frames(3)
	level.hero.stick = Vector2(0.0, -1.0)
	await _frames(240)
	assert_float(level.hero.global_position.z).is_less(-13.0)


func test_pres_de_la_bougie_l_invite_la_nomme() -> void:
	var level: Level = _burrow()
	await _beside_candle(level)
	assert_bool(level.hud.prompt.visible).is_true()
	assert_str(level.hud.prompt.text).contains(_candle(level).settings.blow_prompt)


func test_le_bouton_y_la_souffle_et_la_touche_f_la_rallume() -> void:
	var level: Level = _burrow()
	await _beside_candle(level)
	await _press(_gamepad_y(true))
	await _press(_gamepad_y(false))
	assert_bool(_candle(level).lit).is_false()
	await _press(_key_f(true))
	await _press(_key_f(false))
	assert_bool(_candle(level).lit).is_true()


func test_la_qualite_basse_s_applique_sans_lune_ni_brume_au_sol() -> void:
	var level: Level = _burrow()
	var quality: GraphicsQualityApplier = level.get_node("GraphicsQuality") as GraphicsQualityApplier
	quality.apply(quality.low, level.get_viewport())
	assert_bool((level.get_node("World") as WorldEnvironment).environment.volumetric_fog_enabled).is_false()
	quality.apply(quality.high, level.get_viewport())
#@ 28+


func _stand(level: Level, stand_name: String) -> WeaponStand:
	return level.get_node("Armory/" + stand_name) as WeaponStand


## Pose Bobine tout près du socle, et laisse sa main le voir.
func _beside(level: Level, stand: WeaponStand) -> void:
	await _frames(3)
	level.hero.global_position = stand.global_position + Vector3(0.0, 0.0, 1.4)
	await _frames(4)


func test_elle_arrive_avec_une_baguette_qui_ne_tire_pas() -> void:
	var level: Level = _burrow()
	await _frames(3)
	assert_bool(level.hero.unarmed).is_true()
	var ready_shots: int = level.hero.projectiles.available()
	level.hero.trigger = true
	await _frames(20)
	level.hero.trigger = false
	assert_int(level.hero.projectiles.available()).is_equal(ready_shots)


func test_quatre_armes_attendent_sur_leurs_socles() -> void:
	assert_int((_burrow().get_node("Armory") as Armory).stands.size()).is_equal(4)


func test_le_bouton_y_prend_l_arme_du_socle() -> void:
	var level: Level = _burrow()
	var stand: WeaponStand = _stand(level, "Cork")
	await _beside(level, stand)
	assert_str(level.hud.prompt.text).contains(stand.kit.display_name)
	await _press(_gamepad_y(true))
	await _press(_gamepad_y(false))
	assert_that(level.hero.weapon).is_same(stand.kit)
	assert_that(level.hero.gun.settings).is_same(stand.kit.gun)
	assert_str(level.hud.weapon_name.text).is_equal(stand.kit.display_name)
	assert_bool(stand.empty).is_true()


func test_un_tir_sur_une_boite_de_conserve_l_affiche() -> void:
	var level: Level = _burrow()
	await _frames(3)
	level.hero.equip(_stand(level, "Nailer").kit)
	var can: TinCan = level.get_node("CanSouth") as TinCan
	var from: Vector3 = can.global_position + Vector3(4.0, 1.1, 0.0)
	level.hero.projectiles.fire(from, Vector3.LEFT, 70.0, 12.0, 0.6)
	await _frames(20)
	assert_str((can.get_node("Damage") as Label3D).text).is_equal("12")
#@ all
