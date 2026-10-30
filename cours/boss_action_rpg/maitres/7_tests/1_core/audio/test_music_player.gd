extends GdUnitTestSuite
## Règles de la musique : celle du combat boucle ; elle entre en fondu jusqu'à son volume plein, sort en fondu, puis
## s'arrête ; les bus de la musique et des bruitages existent, les bruitages avec la réverbération de la salle.

const SETTINGS := preload("res://5_data/audio/boss_music.tres")
const STREAM := preload("res://6_assets/Audio/Music/epic_boss_battle.wav")


func _music() -> MusicPlayer:
	var music: MusicPlayer = auto_free(MusicPlayer.new())
	music.settings = SETTINGS
	music.stream = STREAM
	music.bus = &"Music"
	add_child(music)
	return music


func test_la_musique_du_combat_boucle() -> void:
	var wav: AudioStreamWAV = STREAM as AudioStreamWAV
	assert_int(wav.loop_mode).is_equal(AudioStreamWAV.LOOP_FORWARD)
	assert_int(wav.loop_begin).is_equal(0)
	assert_float(wav.get_length()).is_greater(60.0)


func test_elle_entre_en_fondu_sort_en_fondu_et_s_arrete() -> void:
	var music: MusicPlayer = _music()
	var s: MusicSettings = SETTINGS as MusicSettings
	assert_float(music.volume_linear).is_equal(0.0)
	music.start()
	assert_bool(music.playing).is_true()
	music.update(s.fade_in_time * 0.5)
	assert_float(music.level).is_equal_approx(0.5, 0.001)
	music.update(s.fade_in_time)
	assert_float(music.level).is_equal(1.0)
	assert_float(music.volume_linear).is_equal_approx(db_to_linear(s.volume_db), 0.0001)
	music.fade_out()
	music.update(s.fade_out_time * 0.5)
	assert_float(music.level).is_equal_approx(0.5, 0.001)
	assert_bool(music.playing).is_true()
	music.update(s.fade_out_time)
	assert_float(music.level).is_equal(0.0)
	assert_bool(music.playing).is_false()


func test_les_bus_de_la_musique_et_des_bruitages() -> void:
	assert_int(AudioServer.get_bus_index(&"Music")).is_greater(0)
	var sfx: int = AudioServer.get_bus_index(&"SFX")
	assert_int(sfx).is_greater(0)
	assert_object(AudioServer.get_bus_effect(sfx, 0)).is_instanceof(AudioEffectReverb)
