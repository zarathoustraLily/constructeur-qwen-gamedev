extends GdUnitTestSuite
## Juge S2 : connexions déclarées dans res://scenes/main.tscn.

const SCENE := "res://scenes/main.tscn"
const ATTENDUES := [["WaveSpawner", "wave_started", "Hud", "_on_wave_started"], ["WaveSpawner", "wave_cleared", ".", "_on_wave_cleared"]]


func _connexions() -> Array:
	var etat := (load(SCENE) as PackedScene).get_state()
	var resultat: Array = []
	for i in etat.get_connection_count():
		resultat.append([
			str(etat.get_connection_source(i)),
			str(etat.get_connection_signal(i)),
			str(etat.get_connection_target(i)),
			str(etat.get_connection_method(i)),
		])
	return resultat


func test_connexions_declarees_dans_la_scene() -> void:
	var presentes := _connexions()
	for attendue in ATTENDUES:
		assert_array(presentes).contains([attendue])
