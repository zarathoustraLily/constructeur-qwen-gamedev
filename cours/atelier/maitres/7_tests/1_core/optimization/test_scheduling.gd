extends GdUnitTestSuite
## Règles de la mise à jour échelonnée et des niveaux de détail : chaque image sert au plus le budget ; en un cycle,
## chaque objet est servi une fois ; rien à servir sans objets ; le niveau croît avec la distance ; la marge empêche
## de clignoter sur un seuil, mais un vrai franchissement change le niveau.


func test_chaque_image_sert_au_plus_le_budget() -> void:
	var slicer: TimeSlicer = TimeSlicer.new()
	assert_array(slicer.next_batch(10, 4)).is_equal([0, 1, 2, 3])
	assert_array(slicer.next_batch(10, 4)).is_equal([4, 5, 6, 7])
	assert_array(slicer.next_batch(10, 4)).is_equal([8, 9, 0, 1])


func test_en_un_cycle_chaque_objet_est_servi_une_fois() -> void:
	var slicer: TimeSlicer = TimeSlicer.new()
	var served: Dictionary[int, int] = {}
	for _frame: int in TimeSlicer.frames_per_cycle(1000, 64) - 1:
		for index: int in slicer.next_batch(1000, 64):
			served[index] = served.get(index, 0) + 1
	for index: int in slicer.next_batch(1000, 1000 - served.size()):
		served[index] = served.get(index, 0) + 1
	assert_int(served.size()).is_equal(1000)
	for count: int in served.values():
		assert_int(count).is_equal(1)
	assert_int(TimeSlicer.frames_per_cycle(1000, 64)).is_equal(16)


func test_rien_a_servir_sans_objets() -> void:
	assert_array(TimeSlicer.new().next_batch(0, 8)).is_empty()


func test_le_niveau_croit_avec_la_distance() -> void:
	var thresholds: PackedFloat32Array = PackedFloat32Array([10.0, 30.0, 80.0])
	assert_int(DistanceLod.level(5.0, thresholds)).is_equal(0)
	assert_int(DistanceLod.level(15.0, thresholds)).is_equal(1)
	assert_int(DistanceLod.level(200.0, thresholds)).is_equal(3)


func test_la_marge_empeche_de_clignoter_sur_un_seuil() -> void:
	var thresholds: PackedFloat32Array = PackedFloat32Array([10.0, 30.0])
	assert_int(DistanceLod.with_hysteresis(10.5, 0, thresholds, 1.0)).is_equal(0)
	assert_int(DistanceLod.with_hysteresis(9.5, 1, thresholds, 1.0)).is_equal(1)
	assert_int(DistanceLod.with_hysteresis(11.5, 0, thresholds, 1.0)).is_equal(1)
	assert_int(DistanceLod.with_hysteresis(8.5, 1, thresholds, 1.0)).is_equal(0)
