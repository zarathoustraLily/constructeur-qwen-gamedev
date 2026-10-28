extends GdUnitTestSuite
## Règles du service audio : les bus de la musique et des effets existent dès le départ ; un bus demandé est
## créé une seule fois, envoyé vers Master ; un volume se règle et se relit de 0 à 1, 0 coupe le bus, et chaque
## changement est annoncé.
#@ 9+
## Une fois préparé, il joue des effets sur la réserve de voix et la musique en fondu ; avant, il ne fait rien.
#@ all

const TEST_BUS: StringName = &"AtelierTest"


func after_test() -> void:
	var index: int = AudioServer.get_bus_index(TEST_BUS)
	if index >= 0:
		AudioServer.remove_bus(index)
	AudioManager.set_volume(AudioManager.MUSIC, 1.0)
	AudioManager.set_volume(AudioManager.SFX, 1.0)


func test_musique_et_effets_existent_des_le_depart() -> void:
	assert_int(AudioServer.get_bus_index(AudioManager.MUSIC)).is_greater_equal(0)
	assert_int(AudioServer.get_bus_index(AudioManager.SFX)).is_greater_equal(0)


func test_un_bus_demande_est_cree_une_seule_fois_vers_master() -> void:
	var count: int = AudioServer.bus_count
	var index: int = AudioManager.ensure_bus(TEST_BUS)
	assert_int(AudioServer.bus_count).is_equal(count + 1)
	assert_int(AudioServer.get_bus_index(TEST_BUS)).is_equal(index)
	assert_str(String(AudioServer.get_bus_send(index))).is_equal("Master")
	assert_int(AudioManager.ensure_bus(TEST_BUS)).is_equal(index)
	assert_int(AudioServer.bus_count).is_equal(count + 1)


func test_un_volume_se_regle_et_se_relit() -> void:
	AudioManager.set_volume(AudioManager.SFX, 0.5)
	var index: int = AudioServer.get_bus_index(AudioManager.SFX)
	assert_float(AudioServer.get_bus_volume_db(index)).is_equal_approx(-6.0206, 0.001)
	assert_bool(AudioServer.is_bus_mute(index)).is_false()
	assert_float(AudioManager.volume(AudioManager.SFX)).is_equal_approx(0.5, 0.001)


func test_a_zero_le_bus_est_coupe() -> void:
	AudioManager.set_volume(AudioManager.MUSIC, 0.0)
	assert_bool(AudioServer.is_bus_mute(AudioServer.get_bus_index(AudioManager.MUSIC))).is_true()
	assert_float(AudioManager.volume(AudioManager.MUSIC)).is_equal(0.0)


func test_un_volume_hors_bornes_est_borne() -> void:
	AudioManager.set_volume(AudioManager.SFX, 3.0)
	assert_float(AudioManager.volume(AudioManager.SFX)).is_equal_approx(1.0, 0.001)


func test_un_bus_absent_vaut_zero() -> void:
	assert_float(AudioManager.volume(&"BusQuiNExistePas")).is_equal(0.0)


func test_chaque_changement_est_annonce() -> void:
	var received: Array = []
	var listener: Callable = func(bus: StringName, linear: float) -> void: received.append([bus, linear])
	AudioManager.volume_changed.connect(listener)
	AudioManager.set_volume(AudioManager.MUSIC, 0.25)
	AudioManager.volume_changed.disconnect(listener)
	assert_array(received).is_equal([[AudioManager.MUSIC, 0.25]])
#@ 9+


func test_prepare_il_joue_effets_et_musique() -> void:
	AudioManager.setup(preload("res://5_data/audio/audio.tres"))
	assert_bool(AudioManager.is_ready()).is_true()
	AudioManager.setup(preload("res://5_data/audio/audio.tres"))
	assert_int(AudioManager.get_children().size()).is_equal(2)
	var sound: AudioStreamWAV = preload("res://7_tests/1_core/audio/test_sfx_pool.gd").silence(1.0)
	AudioManager.play_sfx(sound)
	var playing: int = AudioManager.sfx().voices().filter(func(v: AudioStreamPlayer) -> bool: return v.playing).size()
	assert_int(playing).is_equal(1)
	AudioManager.play_music(sound)
	assert_that(AudioManager.music().current().stream).is_same(sound)
	for voice: AudioStreamPlayer in AudioManager.sfx().voices():
		voice.stop()
	AudioManager.music().current().stop()
#@ all
