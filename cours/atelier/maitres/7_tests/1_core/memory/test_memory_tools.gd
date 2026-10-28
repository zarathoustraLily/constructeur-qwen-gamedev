extends GdUnitTestSuite
## Règles des outils de mémoire : le cache charge une ressource une seule fois et rend la même instance, ne garde rien
## pour un chemin absent, se vide d'un coup ; la liste faible oublie un objet libéré sans erreur et ne prévient que
## les vivants ; un branchement fait une fois ne se double pas ; tout débrancher retire chaque branchement.

const AUDIO_PATH := "res://5_data/audio/audio.tres"

signal pinged


## Un abonné de test : il compte ses appels.
class Listener extends Node:
	var calls: int = 0

	func ping() -> void:
		calls += 1


func test_le_cache_charge_une_seule_fois_la_meme_instance() -> void:
	var cache: ResourceCache = ResourceCache.new()
	var first: Resource = cache.fetch(AUDIO_PATH)
	var second: Resource = cache.fetch(AUDIO_PATH)
	assert_that(second).is_same(first)
	assert_int(cache.misses).is_equal(1)
	assert_int(cache.hits).is_equal(1)
	assert_bool(cache.has(AUDIO_PATH)).is_true()


func test_le_cache_ne_garde_rien_pour_un_chemin_absent() -> void:
	var cache: ResourceCache = ResourceCache.new()
	assert_object(cache.fetch("res://nulle_part.tres")).is_null()
	assert_int(cache.size()).is_equal(0)


func test_le_cache_se_vide_d_un_coup() -> void:
	var cache: ResourceCache = ResourceCache.new()
	cache.fetch(AUDIO_PATH)
	cache.clear()
	assert_int(cache.size()).is_equal(0)
	assert_bool(cache.has(AUDIO_PATH)).is_false()


func test_la_liste_faible_oublie_un_objet_libere() -> void:
	var listeners: WeakListeners = WeakListeners.new()
	var kept: Listener = auto_free(Listener.new())
	var gone: Listener = Listener.new()
	listeners.add(kept)
	listeners.add(gone)
	listeners.add(kept)
	assert_int(listeners.alive().size()).is_equal(2)
	gone.free()
	assert_int(listeners.alive().size()).is_equal(1)
	assert_int(listeners.notify(&"ping")).is_equal(1)
	assert_int(kept.calls).is_equal(1)


func test_un_branchement_ne_se_double_pas() -> void:
	var listener: Listener = auto_free(Listener.new())
	assert_bool(Connections.connect_once(pinged, listener.ping)).is_true()
	assert_bool(Connections.connect_once(pinged, listener.ping)).is_false()
	pinged.emit()
	assert_int(listener.calls).is_equal(1)
	Connections.disconnect_all(pinged)


func test_tout_debrancher_retire_chaque_branchement() -> void:
	var a: Listener = auto_free(Listener.new())
	var b: Listener = auto_free(Listener.new())
	pinged.connect(a.ping)
	pinged.connect(b.ping)
	assert_int(Connections.disconnect_all(pinged)).is_equal(2)
	pinged.emit()
	assert_int(a.calls + b.calls).is_equal(0)
