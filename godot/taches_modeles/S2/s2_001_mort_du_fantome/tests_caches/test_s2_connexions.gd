extends GdUnitTestSuite
## Juge S2 : connexions déclarées dans res://scenes/ghost.tscn.

const SCENE := "res://scenes/ghost.tscn"
const ATTENDUES := [["HealthComponent", "died", ".", "_on_died"]]


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
