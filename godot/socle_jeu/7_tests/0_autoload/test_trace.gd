extends GdUnitTestSuite
## Le journal de comportement note les changements d'état et les coups, sans qu'on les branche.

const DRONE := "res://3_entities/enemies/drone/drone.tscn"


func test_journal_des_etats_et_des_coups() -> void:
	Trace.clear()
	var drone: Drone = auto_free(load(DRONE).instantiate())
	add_child(drone)
	drone.health.take_damage(1)
	drone.state_machine.transition_to(&"chase")
	var texte := "\n".join(Trace.lines)
	assert_str(texte).contains("Drone : touché -1, vie 2")
	assert_str(texte).contains("Drone : idle → chase")
