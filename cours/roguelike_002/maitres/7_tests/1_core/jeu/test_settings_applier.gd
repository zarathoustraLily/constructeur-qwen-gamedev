extends GdUnitTestSuite
## Appliquer les réglages : le volume de chaque bus du jeu change ; un bus inconnu est ignoré sans erreur.

var _avant: Dictionary[StringName, float] = {}


func before_test() -> void:
	for bus: StringName in [&"Master", &"Musique", &"Effets"]:
		_avant[bus] = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus))


func after_test() -> void:
	for bus: StringName in _avant:
		AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus), _avant[bus])


func test_les_bus_du_jeu_existent() -> void:
	for bus: StringName in [&"Master", &"Musique", &"Effets"]:
		assert_int(AudioServer.get_bus_index(bus)).is_greater_equal(0)


func test_le_volume_de_chaque_bus_change() -> void:
	var settings := GameSettings.new()
	settings.volumes = {&"Musique": 0.25, &"Effets": 0.5}
	SettingsApplier.apply(settings)
	assert_float(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"Musique"))).is_equal_approx(0.25, 0.001)
	assert_float(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"Effets"))).is_equal_approx(0.5, 0.001)


func test_un_bus_inconnu_est_ignore() -> void:
	var settings := GameSettings.new()
	settings.volumes = {&"Inconnu": 0.5}
	SettingsApplier.apply(settings)
	assert_int(AudioServer.get_bus_index(&"Inconnu")).is_less(0)
