extends GdUnitTestSuite
## Règles du contrat d'étape : une étape signale sa fin, ou demande à être rejouée, par un signal.


func _signaux_recus(etape: Step) -> Array[String]:
	var recus: Array[String] = []
	etape.terminee.connect(func() -> void: recus.append("terminee"))
	etape.a_rejouer.connect(func() -> void: recus.append("a_rejouer"))
	return recus


func test_terminer_emet_terminee() -> void:
	var etape: Step = auto_free(Step.new())
	var recus := _signaux_recus(etape)
	etape.terminer()
	assert_array(recus).is_equal(["terminee"])


func test_rejouer_emet_a_rejouer() -> void:
	var etape: Step = auto_free(Step.new())
	var recus := _signaux_recus(etape)
	etape.rejouer()
	assert_array(recus).is_equal(["a_rejouer"])
