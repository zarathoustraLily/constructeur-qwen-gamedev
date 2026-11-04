extends GdUnitTestSuite
## Règles de la boîte de conserve : sa zone reçoit les tirs ; un tir la fait pencher, sans dépasser sa limite ; elle se
## redresse ; elle affiche les dégâts du dernier tir ; elle n'a rien à perdre.

const CAN := preload("res://3_entities/props/tin_can/tin_can.tscn")


func _can() -> TinCan:
	var can: TinCan = auto_free(CAN.instantiate())
	add_child(can)
	return can


func _hurtbox(can: TinCan) -> Hurtbox:
	return can.get_node("Hurtbox") as Hurtbox


func test_sa_zone_recoit_les_tirs() -> void:
	assert_bool(Layers.has(_hurtbox(_can()).collision_layer, Layers.TARGETS)).is_true()


func test_un_tir_la_fait_pencher_sans_depasser_sa_limite() -> void:
	var can: TinCan = _can()
	_hurtbox(can).receive(12.0)
	assert_float(can.tilt).is_equal_approx(12.0 * TinCan.TILT_PER_POINT, 0.001)
	for _i: int in 200:
		_hurtbox(can).receive(52.0)
	assert_float(can.tilt).is_equal_approx(TinCan.TILT_MAX, 0.001)


func test_elle_se_redresse() -> void:
	var can: TinCan = _can()
	_hurtbox(can).receive(12.0)
	can._process(10.0)
	assert_float(can.tilt).is_equal(0.0)


func test_elle_affiche_les_degats_du_dernier_tir() -> void:
	var can: TinCan = _can()
	_hurtbox(can).receive(12.0)
	_hurtbox(can).receive(5.5)
	assert_str((can.get_node("Damage") as Label3D).text).is_equal("6")


func test_elle_n_a_rien_a_perdre() -> void:
	assert_float(_hurtbox(_can()).receive(1000.0)).is_equal(0.0)
