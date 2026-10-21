extends GdUnitTestSuite
## Règles des niveaux : les trois héritent du modèle (joueur, vague, sortie, navigation, éclairage précalculé) ;
## chacun a sa navigation, sa lumière et sa sortie à lui ; dans un niveau, le joueur se tient sur le sol ; chaque
## personnage a sa barre ; vaincu, le joueur revient au départ avec toute sa santé ; la vague vaincue ouvre la
## sortie, et la sortie atteinte lance une vague plus nombreuse.

const TEMPLATE_SCRIPT := preload("res://2_sequence/levels/level_template.gd")
const LEVELS: Array[PackedScene] = [
	preload("res://2_sequence/levels/level_1/level_1.tscn"),
	preload("res://2_sequence/levels/level_2/level_2.tscn"),
	preload("res://2_sequence/levels/level_3/level_3.tscn"),
]


func _frames(count: int) -> void:
	for _frame: int in count:
		await get_tree().physics_frame


func _level(index: int) -> Node3D:
	var level: Node3D = auto_free(LEVELS[index].instantiate())
	add_child(level)
	return level


## Attend les apparitions de toute la vague du niveau.
func _wait_for_wave(level: Node3D) -> WaveObjective:
	var wave := level.get_node("WaveObjective") as WaveObjective
	await _frames(int((wave.settings.first_delay + wave.settings.interval * wave.remaining()) * 60.0) + 10)
	return wave


func test_les_trois_niveaux_heritent_du_modele() -> void:
	for scene: PackedScene in LEVELS:
		var level: Node3D = auto_free(scene.instantiate())
		assert_object(level.get_script()).is_same(TEMPLATE_SCRIPT)
		for path: String in ["Player", "WaveObjective", "ExitPoint", "NavigationRegion3D/Floormap", "WorldBoundary"]:
			assert_object(level.get_node_or_null(path)).override_failure_message(path).is_not_null()
		var region := level.get_node("NavigationRegion3D") as NavigationRegion3D
		assert_object(region.navigation_mesh).is_not_null()
		assert_object((level.get_node("VoxelGI") as VoxelGI).data).is_not_null()


func test_chaque_niveau_a_sa_navigation_sa_lumiere_et_sa_sortie() -> void:
	var meshes: Array[NavigationMesh] = []
	var lights: Array[VoxelGIData] = []
	var exits: Array[Vector3] = []
	for scene: PackedScene in LEVELS:
		var level: Node3D = auto_free(scene.instantiate())
		meshes.append((level.get_node("NavigationRegion3D") as NavigationRegion3D).navigation_mesh)
		lights.append((level.get_node("VoxelGI") as VoxelGI).data)
		exits.append((level.get_node("ExitPoint") as Node3D).position)
	for index: int in [1, 2]:
		assert_object(meshes[index]).is_not_same(meshes[0])
		assert_object(lights[index]).is_not_same(lights[0])
		assert_vector(exits[index]).is_not_equal(exits[0])


func test_dans_chaque_niveau_le_joueur_se_tient_sur_le_sol() -> void:
	for index: int in LEVELS.size():
		var level := _level(index)
		await _frames(30)
		assert_bool((level.get_node("Player") as Player).is_on_floor()).override_failure_message("niveau %d" % (index + 1)).is_true()
		level.free()


func test_vaincu_le_joueur_revient_au_depart_avec_toute_sa_sante() -> void:
	var level := _level(0)
	var player := level.get_node("Player") as Player
	var start := player.global_position
	await _frames(3)
	player.global_position = Vector3(0.0, -6.0, 0.0)
	await _frames(3)
	assert_vector(player.global_position).is_equal_approx(start, Vector3.ONE * 0.2)
	assert_float(player.health_component.current_health).is_equal(player.health_component.max_health)


func test_chaque_personnage_a_sa_barre() -> void:
	var level := _level(0)
	var wave := await _wait_for_wave(level)
	assert_int(level.get_node("Player").find_children("*", "HealthBar", false, false).size()).is_equal(1)
	for enemy: Node in wave.find_children("*", "Enemy", false, false):
		assert_int(enemy.find_children("*", "HealthBar", false, false).size()).is_equal(1)


func test_la_vague_vaincue_ouvre_la_sortie_qui_lance_une_vague_plus_nombreuse() -> void:
	var level := _level(0)
	var wave := await _wait_for_wave(level)
	var exit := level.get_node("ExitPoint") as ExitPoint
	for enemy: Node in wave.find_children("*", "Enemy", false, false):
		var health := enemy.get("health_component") as HealthComponent
		health.take_damage(health.max_health)
	assert_bool(exit.locked).is_false()
	(level.get_node("Player") as Player).global_position = exit.global_position + Vector3.UP
	await _frames(3)
	assert_int(level.get("level_rank")).is_equal(2)
	assert_int(wave.remaining()).is_equal(wave.settings.enemy_count(2))
