extends GdUnitTestSuite
## Règles de la table des sons : ses voix sont prêtes d'avance, sur le bus des bruitages ; un son se joue à sa place,
## avec une de ses variantes, son volume et une hauteur dans ses bornes ; quand toutes les voix ont servi, la plus
## ancienne reprend ; un son sans variante ne joue rien ; la même graine redonne les mêmes tirages.

const SOUNDS := preload("res://5_data/audio/combat_sounds.tres")


func _board(graine: int = 1) -> SoundBoard:
	var board: SoundBoard = auto_free(SoundBoard.new())
	board.rng_seed = graine
	add_child(board)
	return board


func _voix(board: SoundBoard, i: int) -> AudioStreamPlayer3D:
	return board.get_child(i) as AudioStreamPlayer3D


func test_ses_voix_sont_pretes_sur_le_bus_des_bruitages() -> void:
	var board: SoundBoard = _board()
	assert_int(board.get_child_count()).is_equal(board.voice_count)
	for i: int in board.voice_count:
		assert_str(String(_voix(board, i).bus)).is_equal("SFX")


func test_un_son_joue_a_sa_place_avec_une_de_ses_variantes() -> void:
	var board: SoundBoard = _board()
	var cue: SoundCue = (SOUNDS as CombatSoundSet).shot
	var entendus: Array[SoundCue] = []
	board.played_sound.connect(func(c: SoundCue, _at: Vector3) -> void: entendus.append(c))
	board.play(cue, Vector3(2.0, 1.0, -3.0))
	var voix: AudioStreamPlayer3D = _voix(board, 0)
	assert_bool(voix.playing).is_true()
	assert_vector(voix.global_position).is_equal(Vector3(2.0, 1.0, -3.0))
	assert_bool(cue.streams.has(voix.stream)).is_true()
	assert_float(voix.pitch_scale).is_between(cue.pitch_min, cue.pitch_max)
	assert_float(voix.volume_db).is_equal(cue.volume_db)
	assert_float(voix.max_distance).is_equal(cue.max_distance)
	assert_int(board.played).is_equal(1)
	assert_array(entendus).contains_exactly([cue])


func test_toutes_les_voix_servies_la_plus_ancienne_reprend() -> void:
	var board: SoundBoard = _board()
	var cue: SoundCue = (SOUNDS as CombatSoundSet).hit_decor
	for i: int in board.voice_count + 1:
		board.play(cue, Vector3(float(i), 0.0, 0.0))
	assert_float(_voix(board, 0).global_position.x).is_equal(float(board.voice_count))
	assert_float(_voix(board, 1).global_position.x).is_equal(1.0)


func test_un_son_sans_variante_ne_joue_rien() -> void:
	var board: SoundBoard = _board()
	board.play(null, Vector3.ZERO)
	board.play(SoundCue.new(), Vector3.ZERO)
	assert_int(board.played).is_equal(0)
	assert_bool(_voix(board, 0).playing).is_false()


func test_la_meme_graine_redonne_les_memes_tirages() -> void:
	var a: SoundBoard = _board(7)
	var b: SoundBoard = _board(7)
	var cue: SoundCue = (SOUNDS as CombatSoundSet).hero_step
	for i: int in 6:
		a.play(cue, Vector3.ZERO)
		b.play(cue, Vector3.ZERO)
		assert_object(_voix(a, i).stream).is_same(_voix(b, i).stream)
		assert_float(_voix(a, i).pitch_scale).is_equal(_voix(b, i).pitch_scale)


func test_chaque_son_du_combat_a_ses_variantes() -> void:
	var sons: CombatSoundSet = SOUNDS as CombatSoundSet
	var cues: Array[SoundCue] = [sons.shot, sons.hero_step, sons.roll, sons.jump, sons.land, sons.hero_hurt,
		sons.hero_down, sons.heal, sons.hit_decor, sons.hit_golem, sons.hit_weak_point, sons.hit_shield,
		sons.hit_spectre, sons.golem_step, sons.golem_hammer, sons.golem_slam, sons.golem_wake, sons.golem_phase,
		sons.golem_down, sons.spectre_windup, sons.spectre_gone]
	for cue: SoundCue in cues:
		assert_int(cue.streams.size()).is_greater_equal(2)
		assert_float(cue.pitch_min).is_less_equal(cue.pitch_max)
		for s: AudioStream in cue.streams:
			assert_object(s).is_not_null()
