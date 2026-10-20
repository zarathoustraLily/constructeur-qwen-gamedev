extends GdUnitTestSuite
## Règles du contrat d'étape : finir l'étape le signale, avec « done » par défaut, ou la suite demandée.

var _step: Step
var _outcomes: Array[StringName] = []


func before_test() -> void:
	_step = auto_free(Step.new())
	_outcomes.clear()
	_step.finished.connect(func(outcome: StringName) -> void: _outcomes.append(outcome))


func test_finir_signale_done_par_defaut() -> void:
	_step.finish()
	assert_array(_outcomes).is_equal([&"done"])


func test_finir_signale_la_suite_demandee() -> void:
	_step.finish(&"retry")
	_step.finish(&"restart")
	assert_array(_outcomes).is_equal([&"retry", &"restart"])
