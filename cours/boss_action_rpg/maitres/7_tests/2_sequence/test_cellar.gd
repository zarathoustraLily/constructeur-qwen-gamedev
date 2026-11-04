extends GdUnitTestSuite
## Règles de la salle sous le comptoir : Bobine s'y pose sur le plancher, sa caméra est active ; aucun rayon n'en sort ; la
## planche du milieu l'arrête à pied et se passe en sautant ; le seuil du fond dit d'aller au Gardien ; la qualité basse
## s'applique.

const CELLAR := preload("res://2_sequence/cellar.tscn")
## La face sud de la planche du milieu.
const PLANK_Z: float = -15.7
## Le seuil du fond.
const EXIT: Vector3 = Vector3(0.0, 0.0, -36.5)


func _cellar() -> Level:
	var level: Level = auto_free(CELLAR.instantiate())
	add_child(level)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	level.hero.get_node("Input").free()
	return level


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func test_elle_s_y_pose_et_sa_camera_est_active() -> void:
	var level: Level = _cellar()
	await _frames(30)
	assert_bool(level.hero.is_on_floor()).is_true()
	assert_that(level.get_viewport().get_camera_3d()).is_same(level.get_node("OrbitCamera/Arm/Camera"))


func test_aucun_rayon_n_en_sort() -> void:
	var level: Level = _cellar()
	await _frames(3)
	var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state
	for room: Vector3 in [Vector3(0.0, 1.0, -4.0), Vector3(0.0, 1.0, -26.0)]:
		for i: int in 16:
			var angle: float = TAU * i / 16.0
			for aim: Vector3 in [Vector3(cos(angle), 0.0, sin(angle)), Vector3(cos(angle), 1.0, sin(angle)).normalized()]:
				var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(room, room + aim * 80.0, Layers.bit(Layers.WORLD))
				assert_bool(space.intersect_ray(query).is_empty()).override_failure_message("sortie : %s %s" % [room, aim]).is_false()


func test_la_planche_l_arrete_a_pied_et_se_passe_en_sautant() -> void:
	var level: Level = _cellar()
	await _frames(10)
	level.hero.stick = Vector2(0.0, -1.0)
	await _frames(200)
	assert_float(level.hero.global_position.z).is_greater(PLANK_Z - 0.5)
	level.hero.jump_buffer.press()
	await _frames(40)
	assert_float(level.hero.global_position.z).is_less(PLANK_Z - 1.0)


func test_le_seuil_du_fond_dit_d_aller_au_gardien() -> void:
	var level: Level = _cellar()
	await _frames(3)
	var said: Array[String] = []
	level.left.connect(func(path: String) -> void: said.append(path))
	level.hero.global_position = EXIT
	await _frames(4)
	assert_array(said).contains_exactly(["res://2_sequence/main.tscn"])


func test_la_qualite_basse_s_applique() -> void:
	var level: Level = _cellar()
	var quality: GraphicsQualityApplier = level.get_node("GraphicsQuality") as GraphicsQualityApplier
	quality.apply(quality.low, level.get_viewport())
	assert_bool((level.get_node("World") as WorldEnvironment).environment.volumetric_fog_enabled).is_false()
	quality.apply(quality.high, level.get_viewport())
