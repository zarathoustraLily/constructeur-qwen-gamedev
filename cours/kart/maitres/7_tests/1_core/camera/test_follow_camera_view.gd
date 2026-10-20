extends GdUnitTestSuite
## Règles de la caméra qui suit : au départ, elle est derrière la cible ; elle se place au-dessus du point
## suivi ; le stick droit et la souris capturée la font tourner, la souris libre non ; l'inclinaison est
## bornée ; sans entrée pendant le délai, elle revient derrière une cible qui avance, mais pas derrière une
## cible arrêtée.

const CAMERA := preload("res://1_core/camera/follow_camera.tscn")
const SETTINGS := preload("res://5_data/camera/follow_camera.tres")
const STEP := 1.0 / 60.0
const LOOK: Array[String] = ["look_left", "look_right", "look_up", "look_down"]

var _camera: FollowCameraView
var _target: Node3D
var _input: CameraInput


func before_test() -> void:
	_target = auto_free(Node3D.new())
	add_child(_target)
	_camera = auto_free(CAMERA.instantiate())
	_camera.settings = SETTINGS
	_camera.target = _target
	add_child(_camera)
	_camera.set_process(false)
	_input = _camera.get_node("CameraInput")


func after_test() -> void:
	for action: String in LOOK:
		Input.action_release(action)


## Fait avancer la cible vers son avant à `speed` m/s pendant `seconds`, la caméra suivant image par image.
func _follow(speed: float, seconds: float) -> void:
	for _frame: int in int(seconds / STEP):
		_target.global_position += -_target.global_basis.z * speed * STEP
		_camera._process(STEP)


func test_au_depart_la_camera_est_derriere_la_cible() -> void:
	var turned: Node3D = auto_free(Node3D.new())
	turned.rotation.y = 2.0
	add_child(turned)
	var camera: FollowCameraView = auto_free(CAMERA.instantiate())
	camera.settings = SETTINGS
	camera.target = turned
	add_child(camera)
	assert_float(camera.global_basis.z.dot(turned.global_basis.z)).is_greater(0.999)


func test_la_camera_se_place_au_dessus_du_point_suivi() -> void:
	_target.global_position = Vector3(3.0, 2.0, -5.0)
	_camera._process(STEP)
	assert_vector(_camera.global_position).is_equal_approx(Vector3(3.0, 2.0 + SETTINGS.height, -5.0), Vector3.ONE * 0.001)


func test_le_stick_droit_fait_tourner_la_camera() -> void:
	Input.action_press("look_right")
	_camera._process(STEP)
	assert_float(_camera.rotation.y).is_equal_approx(-SETTINGS.stick_speed * STEP, 0.0001)


func test_l_inclinaison_est_bornee() -> void:
	_camera.turn(Vector2(0.0, 10.0))
	assert_float(_camera.rotation.x).is_equal_approx(-SETTINGS.max_pitch, 0.0001)
	_camera.turn(Vector2(0.0, -20.0))
	assert_float(_camera.rotation.x).is_equal_approx(SETTINGS.max_pitch, 0.0001)


func test_la_souris_libre_ne_fait_pas_tourner_la_camera() -> void:
	_input.add_mouse_motion(Vector2(100.0, 0.0))
	_camera._process(STEP)
	assert_float(_camera.rotation.y).is_equal(0.0)


func test_la_souris_capturee_fait_tourner_la_camera() -> void:
	_input.captured = true
	_input.add_mouse_motion(Vector2(100.0, 0.0))
	_camera._process(STEP)
	assert_float(_camera.rotation.y).is_equal_approx(-100.0 * SETTINGS.mouse_sensitivity, 0.0001)


func test_sans_entree_la_camera_revient_derriere_une_cible_qui_avance() -> void:
	_camera.turn(Vector2(PI / 2.0, 0.0))
	_follow(10.0, SETTINGS.reset_delay + 3.0)
	assert_float(_camera.global_basis.z.dot(_target.global_basis.z)).is_greater(0.99)


func test_derriere_une_cible_arretee_la_camera_ne_bouge_pas() -> void:
	_camera.turn(Vector2(PI / 2.0, 0.0))
	_follow(0.0, SETTINGS.reset_delay + 3.0)
	assert_float(_camera.rotation.y).is_equal_approx(-PI / 2.0, 0.0001)


func test_pendant_le_delai_la_camera_reste_ou_on_l_a_tournee() -> void:
	_camera.turn(Vector2(PI / 2.0, 0.0))
	_follow(10.0, SETTINGS.reset_delay * 0.5)
	assert_float(_camera.rotation.y).is_equal_approx(-PI / 2.0, 0.0001)
