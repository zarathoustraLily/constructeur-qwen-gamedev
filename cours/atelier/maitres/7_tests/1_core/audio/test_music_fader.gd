extends GdUnitTestSuite
## Règles des fondus de musique : à puissance constante, la somme des carrés des gains vaut un ; au début du fondu
## seul l'ancien morceau s'entend, à la fin seul le nouveau, et l'ancien lecteur s'arrête ; relancer le même
## morceau ne refait pas de fondu ; les lecteurs sont sur le bus de la musique.

const SETTINGS := preload("res://5_data/audio/audio.tres")
const SFX_SUITE := preload("res://7_tests/1_core/audio/test_sfx_pool.gd")


func _fader() -> MusicFader:
	var fader: MusicFader = auto_free(MusicFader.new())
	fader.settings = SETTINGS
	add_child(fader)
	return fader


func after_test() -> void:
	for child: Node in get_children():
		for player: Node in child.get_children():
			if player is AudioStreamPlayer:
				(player as AudioStreamPlayer).stop()


func test_a_puissance_constante() -> void:
	for i: int in 11:
		var gains: Vector2 = MusicFader.equal_power(float(i) / 10.0)
		assert_float(gains.x * gains.x + gains.y * gains.y).is_equal_approx(1.0, 0.0001)
	assert_vector(MusicFader.equal_power(0.0)).is_equal_approx(Vector2(1.0, 0.0), Vector2.ONE * 0.0001)
	assert_vector(MusicFader.equal_power(1.0)).is_equal_approx(Vector2(0.0, 1.0), Vector2.ONE * 0.0001)


func test_le_nouveau_morceau_monte_et_l_ancien_s_arrete() -> void:
	var fader: MusicFader = _fader()
	fader.play(SFX_SUITE.silence(5.0))
	fader.advance(SETTINGS.crossfade_time)
	var first: AudioStreamPlayer = fader.current()
	fader.play(SFX_SUITE.silence(5.0))
	assert_that(fader.previous()).is_same(first)
	assert_float(fader.current().volume_db).is_equal(Volume.FLOOR_DB)
	assert_float(fader.previous().volume_db).is_equal_approx(0.0, 0.001)
	fader.advance(SETTINGS.crossfade_time * 0.5)
	assert_float(fader.progress).is_equal_approx(0.5, 0.0001)
	fader.advance(SETTINGS.crossfade_time)
	assert_float(fader.current().volume_db).is_equal_approx(0.0, 0.001)
	assert_bool(first.playing).is_false()


func test_relancer_le_meme_morceau_ne_refait_pas_de_fondu() -> void:
	var fader: MusicFader = _fader()
	var song: AudioStreamWAV = SFX_SUITE.silence(5.0)
	fader.play(song)
	fader.advance(SETTINGS.crossfade_time)
	var playing: AudioStreamPlayer = fader.current()
	fader.play(song)
	assert_that(fader.current()).is_same(playing)
	assert_float(fader.progress).is_equal(1.0)


func test_les_lecteurs_sont_sur_le_bus_de_la_musique() -> void:
	var fader: MusicFader = _fader()
	assert_str(String(fader.current().bus)).is_equal("Music")
	assert_str(String(fader.previous().bus)).is_equal("Music")
