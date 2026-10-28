extends GdUnitTestSuite
## Règles du verrouillage : la cible choisie est la plus proche devant, à portée ; une cible derrière ou trop loin est
## ignorée ; sans candidat, rien ; les angles regardent la cible (lacet de l'axe -Z, inclinaison positive vers le bas).


func _at(position: Vector3) -> Node3D:
	var node: Node3D = auto_free(Node3D.new())
	add_child(node)
	node.global_position = position
	return node


func test_la_plus_proche_devant_a_portee() -> void:
	var near: Node3D = _at(Vector3(1.0, 0.0, -5.0))
	var far: Node3D = _at(Vector3(0.0, 0.0, -12.0))
	assert_that(LockOn.pick(Vector3.ZERO, Vector3.FORWARD, [far, near], 30.0)).is_same(near)


func test_derriere_ou_trop_loin_est_ignore() -> void:
	var behind: Node3D = _at(Vector3(0.0, 0.0, 3.0))
	var too_far: Node3D = _at(Vector3(0.0, 0.0, -50.0))
	assert_object(LockOn.pick(Vector3.ZERO, Vector3.FORWARD, [behind, too_far], 30.0)).is_null()


func test_sans_candidat_rien() -> void:
	assert_object(LockOn.pick(Vector3.ZERO, Vector3.FORWARD, [], 30.0)).is_null()


func test_les_angles_regardent_la_cible() -> void:
	var straight: Vector2 = LockOn.look_angles(Vector3.ZERO, Vector3(0.0, 0.0, -10.0))
	assert_float(straight.x).is_equal_approx(0.0, 0.0001)
	assert_float(straight.y).is_equal_approx(0.0, 0.0001)
	var left_below: Vector2 = LockOn.look_angles(Vector3(0.0, 2.0, 0.0), Vector3(-5.0, -3.0, 0.0))
	assert_float(left_below.x).is_equal_approx(PI / 2.0, 0.0001)
	assert_float(left_below.y).is_equal_approx(PI / 4.0, 0.0001)
