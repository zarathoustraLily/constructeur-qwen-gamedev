extends GdUnitTestSuite
## Règles de l'ordre d'exécution : les entrées passent d'abord, l'interface en dernier ; les priorités vont strictement
## croissant, sans doublon ; la lecture avance avant que la caméra ne suive.


func test_les_entrees_d_abord_l_interface_en_dernier() -> void:
	var order: Array[int] = ProcessOrder.sequence()
	assert_int(order[0]).is_equal(ProcessOrder.INPUT)
	assert_int(order[order.size() - 1]).is_equal(ProcessOrder.VIEWS)


func test_les_priorites_vont_strictement_croissant() -> void:
	var order: Array[int] = ProcessOrder.sequence()
	for i: int in range(1, order.size()):
		assert_int(order[i]).is_greater(order[i - 1])


func test_la_lecture_passe_avant_la_camera() -> void:
	assert_int(ProcessOrder.PLAYBACK).is_less(ProcessOrder.CAMERA)
