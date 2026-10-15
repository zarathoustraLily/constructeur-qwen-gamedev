extends GdUnitTestSuite
## Le déroulé : chaque étape de la séquence est une Step.


func test_chaque_etape_respecte_le_contrat() -> void:
	var sequence: Sequence = load("res://2_sequence/sequence.tres")
	assert_int(sequence.steps.size()).is_greater_equal(3)
	for scene in sequence.steps:
		var step: Node = scene.instantiate()
		assert_bool(step is Step).override_failure_message(scene.resource_path).is_true()
		step.free()
