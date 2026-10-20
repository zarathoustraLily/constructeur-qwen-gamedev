extends GdUnitTestSuite
## Règles du poisson procédural : un angle contraint reste à ± la contrainte de son ancre ; posé, sa colonne a
## ses douze articulations à distance fixe, et la garde en nageant ; il tourne vers sa destination ; son
## maillage a deux surfaces, le corps et les nageoires.

var _fish: ProceduralFishView


func before_test() -> void:
	_fish = auto_free(ProceduralFishView.new())
	add_child(_fish)
	_fish.place(Vector3.ZERO, 0.0)


func test_un_angle_contraint_reste_pres_de_son_ancre() -> void:
	var limit := ProceduralFishView.ANGLE_CONSTRAINT
	assert_float(ProceduralFishView.constrain_angle(0.1, 0.0, limit)).is_equal_approx(0.1, 0.0001)
	assert_float(ProceduralFishView.constrain_angle(1.5, 0.0, limit)).is_equal_approx(limit, 0.0001)
	assert_float(ProceduralFishView.constrain_angle(-1.5, 0.0, limit)).is_equal_approx(TAU - limit, 0.0001)


func test_pose_sa_colonne_a_douze_articulations_a_distance_fixe() -> void:
	var link := ProceduralFishView.LINK * _fish.size
	assert_float(_fish.spine_length()).is_equal_approx(link * (ProceduralFishView.JOINT_COUNT - 1), 0.0001)


func test_en_nageant_la_colonne_garde_sa_longueur() -> void:
	_fish.target_position = Vector3(5.0, 0.0, 5.0)
	for _frame: int in 120:
		await get_tree().process_frame
	var link := ProceduralFishView.LINK * _fish.size
	assert_float(_fish.spine_length()).is_equal_approx(link * (ProceduralFishView.JOINT_COUNT - 1), link * 0.05)


func test_il_tourne_vers_sa_destination() -> void:
	_fish.target_position = Vector3(0.0, 0.0, 10.0)
	for _frame: int in 120:
		await get_tree().process_frame
	var to_target := (Vector3(0.0, 0.0, 10.0) - _fish.get_head_position()).normalized()
	assert_float(_fish.get_forward().dot(Vector3(to_target.x, 0.0, to_target.z).normalized())).is_greater(0.7)


func test_son_maillage_a_le_corps_et_les_nageoires() -> void:
	_fish.rebuild_mesh()
	assert_int((_fish.mesh as ArrayMesh).get_surface_count()).is_equal(2)
