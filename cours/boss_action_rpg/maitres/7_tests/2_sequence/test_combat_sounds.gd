extends GdUnitTestSuite
## Règles des sons du combat : chaque événement du héros, du Gardien et des spectres fait jouer son son ; un tir qui
## touche une cible prend le son de la zone touchée, sinon celui du décor ; la musique entre au réveil du Gardien et
## sort à sa chute ; le héros qui court fait un pas par foulée.

const MAIN := preload("res://2_sequence/main.tscn")

var _main: Node3D
var _board: SoundBoard
var _set: CombatSoundSet
var _hero: Hero
var _golem: Golem


func before_test() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_main = auto_free(MAIN.instantiate())
	add_child(_main)
	_board = _main.get_node("SoundBoard") as SoundBoard
	_set = (_main.get_node("CombatSounds") as CombatSounds).sounds
	_hero = _main.get_node("Hero") as Hero
	_golem = _main.get_node("Golem") as Golem
	_hero.get_node("Input").free()
	_golem.machine.process_mode = Node.PROCESS_MODE_DISABLED


func test_les_evenements_du_heros_ont_leur_son() -> void:
	_hero.gun.fired.emit(_hero.gun.global_position, Vector3.FORWARD)
	assert_object(_board.last_cue).is_same(_set.shot)
	_hero.machine.transition_to(&"Roll")
	assert_object(_board.last_cue).is_same(_set.roll)
	_hero.machine.transition_to(&"Jump")
	assert_object(_board.last_cue).is_same(_set.jump)
	_hero.machine.transition_to(&"Move")
	assert_object(_board.last_cue).is_same(_set.land)
	_hero.machine.transition_to(&"Hit")
	assert_object(_board.last_cue).is_same(_set.hero_hurt)
	_hero.machine.transition_to(&"Heal")
	assert_object(_board.last_cue).is_same(_set.heal)


func test_les_evenements_du_gardien_ont_leur_son_et_la_musique_le_suit() -> void:
	var music: MusicPlayer = _main.get_node("Music") as MusicPlayer
	assert_bool(music.playing).is_false()
	_golem.woke.emit()
	assert_object(_board.last_cue).is_same(_set.golem_wake)
	assert_bool(music.playing).is_true()
	_golem.slammed.emit(Vector3(0.0, 0.0, -4.0), 3.5)
	assert_object(_board.last_cue).is_same(_set.golem_slam)
	_golem.hammer.landed.emit(_hero, 30.0)
	assert_object(_board.last_cue).is_same(_set.golem_hammer)
	_golem.phase_changed.emit(2)
	assert_object(_board.last_cue).is_same(_set.golem_phase)
	music.update(10.0)
	_golem.defeated.emit()
	assert_object(_board.last_cue).is_same(_set.golem_down)
	music.update(10.0)
	assert_bool(music.playing).is_false()


func test_un_tir_prend_le_son_de_ce_qu_il_touche() -> void:
	var pool: ProjectilePool = _main.get_node("Projectiles") as ProjectilePool
	var spectre: Spectre = _main.get_node("Spectres/Spectre1") as Spectre
	var ici: Vector3 = Vector3(1.0, 1.0, 1.0)
	spectre.hurtbox.receive(1.0)
	pool.impacted.emit(ici, Vector3.UP, 1.0)
	assert_object(_board.last_cue).is_same(_set.hit_spectre)
	assert_vector(_board.get_child(_board.played - 1).get(&"global_position") as Vector3).is_equal(ici)
	_golem.shield.receive(10.0)
	pool.impacted.emit(ici, Vector3.UP, 0.0)
	assert_object(_board.last_cue).is_same(_set.hit_shield)
	(_golem.get_node("BackWeakPoint") as Hurtbox).receive(10.0)
	pool.impacted.emit(ici, Vector3.UP, 20.0)
	assert_object(_board.last_cue).is_same(_set.hit_weak_point)
	pool.impacted.emit(ici, Vector3.UP, 0.0)
	assert_object(_board.last_cue).is_same(_set.hit_decor)


func test_un_spectre_qui_annonce_et_qui_se_dissipe_se_font_entendre() -> void:
	var spectre: Spectre = _main.get_node("Spectres/Spectre1") as Spectre
	spectre.machine.process_mode = Node.PROCESS_MODE_DISABLED
	spectre.activate(_hero, 0.0)
	spectre.machine.transition_to(&"Windup")
	assert_object(_board.last_cue).is_same(_set.spectre_windup)
	spectre.machine.transition_to(&"Fade")
	assert_object(_board.last_cue).is_same(_set.spectre_gone)


func test_le_heros_qui_court_fait_un_pas_par_foulee() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var pas: Array[int] = [0]
	_board.played_sound.connect(func(cue: SoundCue, _at: Vector3) -> void:
		if cue == _set.hero_step:
			pas[0] += 1)
	# Cinq mètres en ligne droite, au sol, sur 50 images.
	for _i: int in 50:
		_hero.global_position += Vector3(0.1, 0.0, 0.0)
		await get_tree().physics_frame
	assert_int(pas[0]).is_equal(floori(5.0 / _set.hero_stride))
