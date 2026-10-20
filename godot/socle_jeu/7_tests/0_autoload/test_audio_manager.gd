extends GdUnitTestSuite
## Audio global : musique et volumes seulement (ARC-09), aucun bruitage.


func test_volume_du_bus() -> void:
	var bus := AudioServer.get_bus_index(&"Master")
	var avant := AudioServer.get_bus_volume_db(bus)
	AudioManager.set_volume(&"Master", 0.5)
	assert_float(AudioServer.get_bus_volume_db(bus)).is_equal_approx(linear_to_db(0.5), 0.01)
	AudioServer.set_bus_volume_db(bus, avant)


func test_pas_de_bruitage() -> void:
	assert_bool(AudioManager.has_method(&"play_sfx")).is_false()
