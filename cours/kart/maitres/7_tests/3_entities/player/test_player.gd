extends GdUnitTestSuite
## Règles du joueur : sa position est partagée par GameState et les traces de pneus, la caméra suit
## le kart, chaque roue au sol imprime sa trace, et les objets partent à l'horizontale
## dans l'axe de la caméra.

const SCENE_JOUEUR := "res://3_entities/player/player.tscn"
const TracesTemoin := preload("res://7_tests/1_core/effects/tire_marks/traces_temoin.gd")
const PAS := 1.0 / 60.0

var _joueur: Player


func before_test() -> void:
	_joueur = auto_free(load(SCENE_JOUEUR).instantiate())
	add_child(_joueur)
	_joueur.set_process(false)


func test_game_state_suit_la_position_du_kart() -> void:
	_joueur.kart.global_position = Vector3(12, 3, -7)
	_joueur._process(1.0 / 60.0)
	assert_vector(GameState.player_position).is_equal(Vector3(12, 3, -7))


func test_les_objets_partent_a_l_horizontale_dans_l_axe_de_la_camera() -> void:
	_joueur.camera.basis = Basis(Vector3.UP, 0.8) * Basis(Vector3.RIGHT, -0.4)
	var direction := _joueur.get_item_direction()
	var axe := _joueur.camera.basis.z
	assert_float(direction.y).is_equal(0.0)
	assert_float(direction.length()).is_equal_approx(1.0, 0.0001)
	assert_vector(direction).is_equal_approx(Vector3(axe.x, 0, axe.z).normalized(), Vector3.ONE * 0.0001)


func test_la_position_du_joueur_est_celle_du_kart() -> void:
	_joueur.kart.global_position = Vector3(-4, 1, 9)
	assert_vector(_joueur.get_kart_position()).is_equal(Vector3(-4, 1, 9))


func test_la_camera_suit_le_kart_un_metre_au_dessus() -> void:
	_joueur.kart.global_position = Vector3(5, 2, -3)
	_joueur._follow_camera(PAS)
	assert_vector(_joueur.camera.global_position).is_equal_approx(
		_joueur.kart.visual_parent.global_position + Vector3(0, 1, 0), Vector3.ONE * 0.0001)


func test_le_joueur_trouve_les_traces_de_pneus_de_la_scene() -> void:
	var traces: Node = auto_free(TracesTemoin.new())
	add_child(traces)
	var joueur: Player = auto_free(load(SCENE_JOUEUR).instantiate())
	add_child(joueur)
	assert_object(joueur.tire_marks_node).is_same(traces)


func test_des_traces_deja_donnees_ne_sont_pas_remplacees() -> void:
	add_child(auto_free(TracesTemoin.new()))
	var choisies: Node = auto_free(TracesTemoin.new())
	choisies.remove_from_group("tire_marks")
	var joueur: Player = auto_free(load(SCENE_JOUEUR).instantiate())
	joueur.tire_marks_node = choisies
	add_child(joueur)
	assert_object(joueur.tire_marks_node).is_same(choisies)


func test_les_traces_suivent_le_kart() -> void:
	var traces: Node = auto_free(TracesTemoin.new())
	_joueur.tire_marks_node = traces
	_joueur.kart.global_position = Vector3(3, 0, 4)
	_joueur._process(PAS)
	assert_vector(traces.centre).is_equal(Vector3(3, 0, 4))


func test_une_roue_au_sol_imprime_sa_trace_une_roue_en_l_air_une_trace_nulle() -> void:
	_joueur.kart.set_physics_process(false)
	var roues: Array[Wheel] = _joueur.kart.wheels
	assert_array(roues).is_not_empty()
	var traces: Node = auto_free(TracesTemoin.new())
	_joueur.tire_marks_node = traces
	_joueur._process(PAS)
	assert_array(traces.traces.map(func(t: Array) -> Array: return [t[1], t[2]])).is_equal(roues.map(func(_r: Wheel) -> Array: return [0.0, 0.0]))
	# Un sol (calque Terrain) juste sous le départ des rayons des roues.
	var hauteur := INF
	for roue in roues:
		hauteur = minf(hauteur, roue.raycast.global_position.y)
	var sol: StaticBody3D = auto_free(StaticBody3D.new())
	sol.collision_layer = 8
	var forme := CollisionShape3D.new()
	forme.shape = BoxShape3D.new()
	forme.shape.size = Vector3(40, 1, 40)
	sol.add_child(forme)
	sol.position = _joueur.kart.global_position * Vector3(1, 0, 1) + Vector3(0, hauteur - 0.1 - 0.5, 0)
	add_child(sol)
	await get_tree().physics_frame
	for roue in roues:
		roue.raycast.force_raycast_update()
		assert_bool(roue.is_grounded()).override_failure_message("roue %s en l'air" % roue.name).is_true()
	traces.traces.clear()
	_joueur._process(PAS)
	assert_array(traces.traces.map(func(t: Array) -> Array: return [t[1], t[2]])).is_equal(roues.map(func(_r: Wheel) -> Array: return [1.0, 9.0]))
	assert_vector(traces.traces[0][0]).is_equal(roues[0].get_wheel_position())
