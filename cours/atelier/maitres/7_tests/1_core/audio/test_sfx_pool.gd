extends GdUnitTestSuite
## Règles de la réserve d'effets : autant de voix que les réglages, sur le bus des effets ; un effet prend une voix
## libre sans couper celle qui joue ; quand toutes jouent, la plus ancienne est reprise ; hauteur et volume varient
## dans leurs bornes ; la même graine redonne les mêmes variations.

const SETTINGS := preload("res://5_data/audio/audio.tres")


static func silence(seconds: float) -> AudioStreamWAV:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var data: PackedByteArray = PackedByteArray()
	data.resize(int(22050.0 * seconds) * 2)
	wav.data = data
	return wav


func _pool() -> SfxPool:
	var pool: SfxPool = auto_free(SfxPool.new())
	pool.settings = SETTINGS
	add_child(pool)
	return pool


func after_test() -> void:
	for child: Node in get_children():
		for player: Node in child.get_children():
			if player is AudioStreamPlayer:
				(player as AudioStreamPlayer).stop()


func test_autant_de_voix_que_les_reglages_sur_le_bus_des_effets() -> void:
	var pool: SfxPool = _pool()
	assert_int(pool.voices().size()).is_equal(SETTINGS.sfx_voices)
	for voice: AudioStreamPlayer in pool.voices():
		assert_str(String(voice.bus)).is_equal("SFX")


func test_un_effet_prend_une_voix_libre_sans_couper_l_autre() -> void:
	var pool: SfxPool = _pool()
	var first: AudioStreamPlayer = pool.play(silence(2.0))
	var second: AudioStreamPlayer = pool.play(silence(2.0))
	assert_that(second).is_not_same(first)
	assert_bool(first.playing).is_true()
	assert_bool(second.playing).is_true()


func test_quand_toutes_jouent_la_plus_ancienne_est_reprise() -> void:
	var pool: SfxPool = _pool()
	var players: Array[AudioStreamPlayer] = []
	for _i: int in SETTINGS.sfx_voices:
		players.append(pool.play(silence(2.0)))
	assert_that(pool.play(silence(2.0))).is_same(players[0])
	assert_that(pool.play(silence(2.0))).is_same(players[1])


func test_hauteur_et_volume_varient_dans_leurs_bornes() -> void:
	var pool: SfxPool = _pool()
	for _i: int in 30:
		var player: AudioStreamPlayer = pool.play(silence(0.1))
		assert_float(player.pitch_scale).is_between(1.0 - SETTINGS.pitch_variation, 1.0 + SETTINGS.pitch_variation)
		assert_float(absf(player.volume_db)).is_less_equal(SETTINGS.volume_variation_db)
		player.stop()


func test_la_meme_graine_redonne_les_memes_variations() -> void:
	var a: RandomNumberGenerator = RandomNumberGenerator.new()
	var b: RandomNumberGenerator = RandomNumberGenerator.new()
	a.seed = 42
	b.seed = 42
	assert_float(SfxPool.jitter(1.0, 0.1, a)).is_equal(SfxPool.jitter(1.0, 0.1, b))
	assert_float(SfxPool.jitter(2.0, 0.0, a)).is_equal(2.0)
