extends GdUnitTestSuite
## Règles des niveaux : les trois héritent du modèle (joueur, vague, sortie, navigation, éclairage précalculé) ;
## chacun a sa navigation, sa lumière et sa sortie à lui ; dans un niveau, le joueur se tient sur le sol ; chaque
## personnage a sa barre.
#@ 11
## Vaincu, le joueur revient au départ avec toute sa santé ; la vague vaincue ouvre la sortie, et la sortie
## atteinte lance une vague plus nombreuse.
#@ 12+
## Chaque niveau est une étape : la vague vaincue ouvre la sortie ; la sortie atteinte, le rang monte et l'étape
## finit ; vaincu, le joueur ramène le rang à 1 et le niveau demande à être rejoué ; la vague suit le rang de
## GameState ; le joueur gardé par GameFlow remplace celui du niveau.
#@ all

const TEMPLATE_SCRIPT := preload("res://2_sequence/levels/level_template.gd")
#@ 12+
const PLAYER := preload("res://3_entities/player/player.tscn")
#@ all
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

#@ 11


func test_vaincu_le_joueur_revient_au_depart_avec_toute_sa_sante() -> void:
	var level := _level(0)
	var player := level.get_node("Player") as Player
	var start := player.global_position
	await _frames(3)
	player.global_position = Vector3(0.0, -6.0, 0.0)
	await _frames(3)
	assert_vector(player.global_position).is_equal_approx(start, Vector3.ONE * 0.2)
	assert_float(player.health_component.current_health).is_equal(player.health_component.max_health)

#@ all


func test_chaque_personnage_a_sa_barre() -> void:
	var level := _level(0)
	var wave := await _wait_for_wave(level)
	assert_int(level.get_node("Player").find_children("*", "HealthBar", false, false).size()).is_equal(1)
	for enemy: Node in wave.find_children("*", "Enemy", false, false):
		assert_int(enemy.find_children("*", "HealthBar", false, false).size()).is_equal(1)

#@ 11


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
#@ 12+


var _saved_rank: int


func before_test() -> void:
	_saved_rank = GameState.level
	GameState.reset()


func after_test() -> void:
	GameState.level = _saved_rank


## Le niveau comme étape. Sa racine est un Node3D dont le script étend Step (un Node) : la conversion passe par Node.
func _step(level: Node) -> Step:
	return level as Step


func test_chaque_niveau_est_une_etape() -> void:
	for scene: PackedScene in LEVELS:
		var level: Node = auto_free(scene.instantiate())
		assert_bool(level is Step).is_true()


func test_la_sortie_atteinte_le_rang_monte_et_l_etape_finit() -> void:
	var level := _level(0)
	var outcomes: Array[StringName] = []
	_step(level).finished.connect(func(outcome: StringName) -> void: outcomes.append(outcome))
	var wave := await _wait_for_wave(level)
	var exit := level.get_node("ExitPoint") as ExitPoint
	for enemy: Node in wave.find_children("*", "Enemy", false, false):
		var health := enemy.get("health_component") as HealthComponent
		health.take_damage(health.max_health)
	assert_bool(exit.locked).is_false()
	(level.get_node("Player") as Player).global_position = exit.global_position + Vector3.UP
	await _frames(3)
	assert_array(outcomes).is_equal([&"done"])
	assert_int(GameState.level).is_equal(2)


func test_vaincu_le_rang_revient_a_un_et_le_niveau_demande_a_etre_rejoue() -> void:
	GameState.level = 3
	var level := _level(0)
	var outcomes: Array[StringName] = []
	_step(level).finished.connect(func(outcome: StringName) -> void: outcomes.append(outcome))
	await _frames(3)
	var player := level.get_node("Player") as Player
	player.health_component.take_damage(player.health_component.max_health)
	assert_array(outcomes).contains([&"retry"])
	assert_int(GameState.level).is_equal(1)


func test_la_vague_suit_le_rang_de_game_state() -> void:
	GameState.level = 4
	var level := _level(0)
	var wave := level.get_node("WaveObjective") as WaveObjective
	assert_int(wave.remaining()).is_equal(wave.settings.enemy_count(4))


func test_le_joueur_garde_par_game_flow_remplace_celui_du_niveau() -> void:
	# Un joueur qui a déjà joué un niveau : entré dans l'arbre (son _ready a tourné), amélioré, puis retiré, comme
	# GameFlow le garde de côté.
	var carried := PLAYER.instantiate() as Player
	add_child(carried)
	carried.damage_stat = 150.0
	remove_child(carried)
	GameFlow.set("_carried_player", carried)
	var level := _level(0)
	var player := level.get_node("Player") as Player
	assert_object(player).is_same(carried)
	assert_float(player.damage_stat).is_equal(150.0)
	assert_object(GameFlow.take_player()).is_null()
#@ all

