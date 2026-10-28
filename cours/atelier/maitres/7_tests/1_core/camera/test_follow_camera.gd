extends GdUnitTestSuite
## Règles de la caméra qui suit : elle vise au-dessus de sa cible ; elle la rejoint en douceur, au même rythme quel
## que soit le nombre d'images ; au stick, elle tourne autour et son lacet reste entre -PI et PI ; « avant » suit le
## lacet ; un mur entre elle et la cible raccourcit le bras.

const CAMERA := preload("res://1_core/camera/follow_camera.tscn")
const SETTINGS := preload("res://5_data/camera/follow_camera.tres")

var _target: Node3D


func before_test() -> void:
	_target = auto_free(Node3D.new())
	add_child(_target)


func _camera() -> FollowCamera:
	var camera: FollowCamera = CAMERA.instantiate() as FollowCamera
	camera.target = _target
	add_child(auto_free(camera))
	return camera


func test_elle_vise_au_dessus_de_sa_cible() -> void:
	var point: Vector3 = FollowCamera.focus_point(Vector3(2.0, 0.0, 1.0), SETTINGS)
	assert_vector(point).is_equal(Vector3(2.0, SETTINGS.target_height, 1.0))


func test_le_suivi_ne_depend_pas_du_nombre_d_images() -> void:
	var once: Vector3 = FollowCamera.smooth(Vector3.ZERO, Vector3(10.0, 0.0, 0.0), 8.0, 0.1)
	var halves: Vector3 = FollowCamera.smooth(FollowCamera.smooth(Vector3.ZERO, Vector3(10.0, 0.0, 0.0), 8.0, 0.05),
		Vector3(10.0, 0.0, 0.0), 8.0, 0.05)
	assert_float(once.x).is_equal_approx(halves.x, 0.0001)
	assert_float(once.x).is_equal_approx(10.0 * (1.0 - exp(-0.8)), 0.0001)


func test_elle_rejoint_sa_cible_en_douceur() -> void:
	var camera: FollowCamera = _camera()
	_target.global_position = Vector3(5.0, 0.0, 0.0)
	camera.follow(1.0 / 60.0)
	assert_float(camera.global_position.x).is_between(0.0, 2.0)
	for _i: int in 240:
		camera.follow(1.0 / 60.0)
	assert_vector(camera.global_position).is_equal_approx(FollowCamera.focus_point(_target.global_position, SETTINGS),
		Vector3.ONE * 0.01)


func test_au_stick_elle_tourne_et_le_lacet_reste_borne() -> void:
	var camera: FollowCamera = _camera()
	camera.orbit(1.0, 0.5)
	assert_float(camera.yaw).is_equal_approx(deg_to_rad(SETTINGS.orbit_speed_degrees) * 0.5, 0.0001)
	camera.orbit(5.0, 0.5)
	assert_float(camera.yaw).is_between(-PI, PI)
	assert_float(absf(camera.yaw)).is_equal_approx(PI, 0.0001)


func test_avant_suit_le_lacet() -> void:
	var camera: FollowCamera = _camera()
	assert_vector(camera.ground_forward()).is_equal_approx(Vector3(0.0, 0.0, -1.0), Vector3.ONE * 0.0001)
	camera.yaw = PI / 2.0
	assert_vector(camera.ground_forward()).is_equal_approx(Vector3(-1.0, 0.0, 0.0), Vector3.ONE * 0.0001)


func test_un_mur_raccourcit_le_bras() -> void:
	var camera: FollowCamera = _camera()
	var wall: StaticBody3D = StaticBody3D.new()
	wall.collision_layer = Layers.bit(Layers.WORLD)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(20.0, 20.0, 0.5)
	shape.shape = box
	wall.add_child(shape)
	wall.position = camera.global_position + Vector3(0.0, 0.0, 3.0)
	add_child(auto_free(wall))
	for _i: int in 5:
		await get_tree().physics_frame
	var arm: SpringArm3D = camera.get_node("Arm") as SpringArm3D
	assert_float(arm.get_hit_length()).is_less(SETTINGS.distance - 1.0)
