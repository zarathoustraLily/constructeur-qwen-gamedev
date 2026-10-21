extends GdUnitTestSuite
## Règles de la vague : elle prépare autant d'ennemis que la courbe le dit pour le rang du niveau ; personne avant
## le premier délai, puis un ennemi par intervalle, chacun signalé ; vaincus tous, elle est vaincue ; une même
## graine fait la même vague (sortes et places) ; les ennemis pas encore apparus partent avec elle.

const MELEE := preload("res://3_entities/enemy/melee_enemy.tscn")
const RANGED := preload("res://3_entities/enemy/ranged_enemy.tscn")
const SETTINGS := preload("res://5_data/levels/wave.tres")


func _wave() -> WaveObjective:
	var wave := WaveObjective.new()
	wave.settings = SETTINGS
	wave.enemy_scenes = [MELEE, RANGED]
	var timer := Timer.new()
	timer.name = "SpawnTimer"
	timer.one_shot = true
	wave.add_child(timer)
	add_child(wave)
	return wave


func _frames(seconds: float) -> void:
	for _frame: int in int(seconds * 60.0):
		await get_tree().physics_frame


func test_la_courbe_donne_trois_ennemis_au_premier_niveau() -> void:
	assert_int(SETTINGS.enemy_count(1)).is_equal(3)
	assert_int(SETTINGS.enemy_count(5)).is_greater(SETTINGS.enemy_count(1))


func test_personne_avant_le_premier_delai_puis_un_par_intervalle() -> void:
	var wave: WaveObjective = auto_free(_wave())
	var spawned: Array[Enemy] = []
	wave.enemy_spawned.connect(func(enemy: Enemy) -> void: spawned.append(enemy))
	wave.start(1)
	assert_int(wave.remaining()).is_equal(3)
	await _frames(SETTINGS.first_delay - 0.2)
	assert_array(spawned).is_empty()
	await _frames(0.3)
	assert_int(spawned.size()).is_equal(1)
	await _frames(SETTINGS.interval * 2.0)
	assert_int(spawned.size()).is_equal(3)


func test_vaincus_tous_la_vague_est_vaincue() -> void:
	var wave: WaveObjective = auto_free(_wave())
	var cleared: Array[int] = [0]
	wave.cleared.connect(func() -> void: cleared[0] += 1)
	wave.start(1)
	await _frames(SETTINGS.first_delay + SETTINGS.interval * 2.0 + 0.2)
	for enemy: Node in wave.find_children("*", "Enemy", false, false):
		var health := enemy.get("health_component") as HealthComponent
		health.take_damage(health.max_health)
	assert_int(cleared[0]).is_equal(1)
	assert_int(wave.remaining()).is_equal(0)


func test_une_meme_graine_fait_la_meme_vague() -> void:
	var first: Array[String] = []
	var second: Array[String] = []
	for record: Array[String] in [first, second]:
		var wave := _wave()
		wave.enemy_spawned.connect(func(enemy: Enemy) -> void: record.append("%s %s" % [enemy.scene_file_path.get_file(), enemy.position.snappedf(0.01)]))
		wave.start(1)
		await _frames(SETTINGS.first_delay + SETTINGS.interval * 2.0 + 0.2)
		wave.free()
	assert_int(first.size()).is_equal(3)
	assert_array(second).is_equal(first)


func test_les_ennemis_pas_encore_apparus_partent_avec_elle() -> void:
	var wave := _wave()
	wave.start(1)
	await get_tree().physics_frame
	var waiting := wave.remaining()
	assert_int(waiting).is_equal(3)
	# GdUnit compte les nœuds orphelins de chaque test : des ennemis restés en mémoire feraient échouer la suite.
	wave.free()
