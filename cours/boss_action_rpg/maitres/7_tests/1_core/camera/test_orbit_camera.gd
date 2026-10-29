extends GdUnitTestSuite
## Règles de la caméra à la troisième personne : l'inclinaison reste dans ses bornes et le lacet entre -PI et PI ;
## verrouillée, elle ignore le stick et se tourne vers sa cible ; elle rejoint le héros en douceur ; en visant, le bras
## raccourcit ; un mur raccourcit le bras ; la caméra est décalée vers l'épaule ; une cible libérée déverrouille.
#@ 7+
## Au départ, elle se place derrière le héros, dans la direction où il regarde.
#@ 13+
## Elle tremble de moins en moins puis s'arrête ; un tremblement plus faible ne remplace pas celui en cours.
#@ all

const CAMERA := preload("res://1_core/camera/orbit_camera.tscn")
const SETTINGS := preload("res://5_data/camera/camera_settings.tres")
const DT: float = 1.0 / 60.0

var _hero: Node3D


func before_test() -> void:
	_hero = auto_free(Node3D.new())
	add_child(_hero)


func _camera() -> OrbitCamera:
	var orbit: OrbitCamera = CAMERA.instantiate() as OrbitCamera
	orbit.get_node("Input").free()
	orbit.target = _hero
	add_child(auto_free(orbit))
	return orbit


func test_l_inclinaison_reste_dans_ses_bornes_et_le_lacet_boucle() -> void:
	var orbit: OrbitCamera = _camera()
	orbit.rotate_by(0.0, 10.0)
	assert_float(orbit.pitch).is_equal_approx(deg_to_rad(SETTINGS.pitch_max_degrees), 0.0001)
	orbit.rotate_by(0.0, -10.0)
	assert_float(orbit.pitch).is_equal_approx(deg_to_rad(SETTINGS.pitch_min_degrees), 0.0001)
	orbit.rotate_by(TAU + 0.5, 0.0)
	assert_float(orbit.yaw).is_between(-PI, PI)


func test_verrouillee_elle_ignore_le_stick_et_regarde_sa_cible() -> void:
	var orbit: OrbitCamera = _camera()
	var target: Node3D = auto_free(Node3D.new())
	add_child(target)
	target.global_position = Vector3(-10.0, 1.6, 0.0)
	orbit.lock(target)
	var before_yaw: float = orbit.yaw
	orbit.rotate_by(1.0, 0.0)
	assert_float(orbit.yaw).is_equal(before_yaw)
	for _i: int in 180:
		orbit.follow(DT)
	assert_float(absf(angle_difference(orbit.yaw, PI / 2.0))).is_less(0.01)


func test_elle_rejoint_le_heros_en_douceur() -> void:
	var orbit: OrbitCamera = _camera()
	_hero.global_position = Vector3(6.0, 0.0, 0.0)
	orbit.follow(DT)
	assert_float(orbit.global_position.x).is_between(0.0, 3.0)
	for _i: int in 240:
		orbit.follow(DT)
	assert_vector(orbit.global_position).is_equal_approx(OrbitCamera.focus(_hero.global_position, SETTINGS), Vector3.ONE * 0.01)


func test_en_visant_le_bras_raccourcit() -> void:
	var orbit: OrbitCamera = _camera()
	orbit.aiming = true
	for _i: int in 240:
		orbit.follow(DT)
	assert_float((orbit.get_node("Arm") as SpringArm3D).spring_length).is_equal_approx(SETTINGS.aim_distance, 0.01)


func test_la_camera_est_decalee_vers_l_epaule() -> void:
	var orbit: OrbitCamera = _camera()
	orbit.follow(DT)
	assert_float((orbit.get_node("Arm/Camera") as Camera3D).position.x).is_equal_approx(SETTINGS.shoulder, 0.0001)


func test_un_mur_raccourcit_le_bras() -> void:
	var orbit: OrbitCamera = _camera()
	orbit.pitch = 0.0
	orbit.apply_rotation()
	var wall: StaticBody3D = StaticBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(20.0, 20.0, 0.5)
	shape.shape = box
	wall.add_child(shape)
	wall.position = orbit.global_position + Vector3(0.0, 0.0, 2.0)
	add_child(auto_free(wall))
	for _i: int in 5:
		await get_tree().physics_frame
	assert_float((orbit.get_node("Arm") as SpringArm3D).get_hit_length()).is_less(SETTINGS.distance - 1.0)


func test_une_cible_liberee_deverrouille() -> void:
	var orbit: OrbitCamera = _camera()
	var target: Node3D = Node3D.new()
	add_child(target)
	orbit.lock(target)
	target.free()
	orbit.follow(DT)
	assert_object(orbit.locked).is_null()
#@ 7+


func test_au_depart_elle_regarde_ou_regarde_le_heros() -> void:
	_hero.rotation.y = PI
	var orbit: OrbitCamera = _camera()
	assert_float(absf(angle_difference(orbit.yaw, PI))).is_less(0.0001)
#@ all
#@ 13+


func test_elle_tremble_de_moins_en_moins_puis_s_arrete() -> void:
	var orbit: OrbitCamera = _camera()
	var camera: Camera3D = orbit.get_node("Arm/Camera") as Camera3D
	orbit.shake(0.4, 0.5)
	assert_float(orbit.current_shake()).is_equal_approx(0.4, 0.001)
	orbit.follow(0.25)
	assert_float(orbit.current_shake()).is_equal_approx(0.2, 0.001)
	assert_float(Vector2(camera.h_offset, camera.v_offset).length()).is_greater(0.0)
	orbit.shake(0.1, 1.0)
	assert_float(orbit.current_shake()).is_equal_approx(0.2, 0.001)
	orbit.follow(0.3)
	assert_float(orbit.current_shake()).is_equal(0.0)
	assert_float(camera.h_offset).is_equal(0.0)
	assert_float(camera.v_offset).is_equal(0.0)
#@ all
