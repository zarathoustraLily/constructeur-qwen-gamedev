extends GdUnitTestSuite
## Niveau 1 : ses ennemis sont posés dans la scène, chaque ennemi détruit rapporte ses points, le
## niveau finit quand ils sont tous détruits, et il tient son budget (nœuds, fuites à la fermeture).

const LEVEL := "res://2_sequence/levels/level_01/level_01.tscn"


# GdUnitSceneRunner déclare simulate_frames() abstraite, sans corps : l'analyse n'y voit pas d'await.
# Son implémentation (GdUnitSceneRunnerImpl) attend les images : l'avertissement « await inutile » ne vaut
# pas ici, et sans await les images ne seraient pas jouées.
func test_ennemis_poses_points_et_fin_du_niveau() -> void:
	var level: LevelBase = auto_free(load(LEVEL).instantiate())
	add_child(level)
	GameState.reset(level.rules.start_lives)
	var issues: Array[StringName] = []
	level.finished.connect(func(o: StringName) -> void: issues.append(o))
	var ennemis := level.alive_enemies()
	assert_int(ennemis.size()).is_greater(0)
	var attendu := 0
	for e in ennemis:
		var drone := e as Drone
		attendu += drone.stats.score_value
		drone.health.take_damage(drone.stats.max_health)
	assert_array(level.alive_enemies()).is_empty()
	assert_int(GameState.score).is_equal(attendu)
	await get_tree().create_timer(level.rules.level_end_delay + 0.2).timeout
	assert_array(issues).contains_exactly([&"done"])


func test_budget_du_niveau() -> void:
	var avant := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var level: LevelBase = load(LEVEL).instantiate()
	var budget := level.budget
	add_child(level)
	await await_idle_frame()
	assert_int(level.get_tree().get_node_count()).is_less_equal(budget.max_nodes)
	level.free()
	await await_idle_frame()
	var apres := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	assert_int(int(apres - avant)).is_less_equal(budget.max_orphans_after_free)


func test_les_drones_attaquent_le_joueur() -> void:
	var runner := scene_runner(LEVEL)
	var level := runner.scene() as LevelBase
	level.player.global_position = Vector3(0, 0, 2)
	Trace.clear()
	@warning_ignore("redundant_await")
	await runner.simulate_frames(240)
	var texte := "\n".join(Trace.lines)
	assert_str(texte).contains("chase → attack")
	assert_int(level.player.health.current_health).is_less(level.player.stats.max_health)
