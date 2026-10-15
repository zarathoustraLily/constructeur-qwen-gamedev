extends GdUnitTestSuite
## Les définitions de 5_data se valident au chargement (DAT-07) ; une définition fausse est nommée.

const DEFINITIONS: Array[String] = [
	"res://5_data/actors/player.tres",
	"res://5_data/enemies/drone.tres",
	"res://5_data/weapons/blaster.tres",
	"res://5_data/weapons/drone_gun.tres",
	"res://5_data/game/game_rules.tres",
]


func test_definitions_du_jeu_valides() -> void:
	for path in DEFINITIONS:
		var definition: Resource = load(path)
		var errors: PackedStringArray = definition.call(&"validate")
		assert_array(Array(errors)).override_failure_message(path).is_empty()


func test_definition_fausse_nommee() -> void:
	var stats := ActorStats.new()
	stats.id = &"Drone Rouge"
	var errors := stats.validate()
	assert_int(errors.size()).is_greater_equal(2)
	assert_str("\n".join(errors)).contains("max_health")
