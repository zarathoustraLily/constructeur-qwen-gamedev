extends GdUnitTestSuite
## Règles de l'ordre d'exécution : les entrées passent d'abord, le cadre de sélection en dernier ; les priorités vont
## strictement croissant, sans doublon.


func test_les_entrees_d_abord_le_cadre_en_dernier() -> void:
	var order: Array[int] = ProcessOrder.sequence()
	assert_int(order[0]).is_equal(ProcessOrder.INPUT)
	assert_int(order[order.size() - 1]).is_equal(ProcessOrder.OVERLAY)


func test_les_priorites_vont_strictement_croissant() -> void:
	var order: Array[int] = ProcessOrder.sequence()
	for i: int in range(1, order.size()):
		assert_int(order[i]).is_greater(order[i - 1])


func test_le_document_passe_avant_les_vues() -> void:
	assert_int(ProcessOrder.DOCUMENT).is_less(ProcessOrder.VIEWS)
