extends GdUnitTestSuite
#@ 1
## Règles de la scène principale : elle montre à chaque image les commandes que l'adaptateur a lues, et la
## vibration du saut est réglée.
#@ 2
## Règles de la scène principale : elle montre à chaque image les commandes que le kart a reçues, la
## vibration du saut est réglée et branchée sur le saut du kart, et le kart se pose sur le sol.
#@ 3
## Règles de la scène principale : elle montre à chaque image les commandes que le kart a reçues, la
## vibration du saut est réglée et branchée sur le saut du kart, le kart se pose sur le sol et décolle de
## la rampe, et la caméra le suit.
#@ 4-5
## Règles de la scène principale : elle montre à chaque image les commandes que le kart a reçues, la
## vibration du saut est réglée et branchée sur le saut du kart, le kart se pose sur l'île au départ, et la
## caméra le suit.
#@ 6-10
## Règles de la scène principale : elle montre à chaque image les commandes que le kart a reçues, la
## vibration du saut est réglée et branchée sur le saut du kart, le kart se pose sur l'île au départ, sa
## position est recopiée dans GameState pour les shaders, et la caméra le suit.
#@ 11+
## Règles de la scène principale : elle montre à chaque image les commandes que le kart a reçues, la
## vibration du saut est réglée et branchée sur le saut du kart, le kart se pose sur l'île au départ, sa
## position est recopiée dans GameState pour les shaders, et la caméra le suit. La météo donne sa pluie et son
## mouillage aux shaders et aux roues, et l'orage lance des éclairs sur le kart.
#@ all

const MAIN := preload("res://2_sequence/main.tscn")


func after_test() -> void:
	Input.action_release("move_forward")


func test_la_scene_montre_les_commandes_lues() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	Input.action_press("move_forward")
	# Le signal physics_frame part avant que les nœuds ne jouent leur image : trois images pour que la lecture
	# des commandes, puis leur affichage, aient eu lieu.
	for _frame: int in 3:
		await get_tree().physics_frame
	assert_float((main.get_node("InputDisplay/Panel/Rows/Throttle") as ProgressBar).value).is_equal_approx(1.0, 0.001)


func test_la_vibration_du_saut_est_reglee() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	var rumble: Rumble = main.get("jump_rumble")
	assert_object(rumble).is_not_null()
	assert_float(rumble.duration).is_greater(0.0)
	assert_float(maxf(rumble.weak_magnitude, rumble.strong_magnitude)).is_greater(0.0)
#@ 2+


func test_la_vibration_est_branchee_sur_le_saut_du_kart() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	var kart := main.get_node("Kart") as Kart
	assert_int(kart.jumped.get_connections().size()).is_equal(1)
#@ 2-3


func test_le_kart_se_pose_sur_le_sol_de_l_aire_d_essai() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	var kart := main.get_node("Kart") as Kart
	for _frame: int in 60:
		await get_tree().physics_frame
	assert_bool(kart.is_on_ground()).is_true()
	assert_float(kart.global_position.y).is_between(-0.5, 1.0)


func test_en_foncant_sur_la_rampe_le_kart_decolle() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	var kart := main.get_node("Kart") as Kart
	kart.input = null
	kart.commands.throttle = 1.0
	var highest := kart.global_position.y
	var airborne := false
	for _frame: int in 240:
		await get_tree().physics_frame
		highest = maxf(highest, kart.global_position.y)
		airborne = airborne or (kart.global_position.z < -18.0 and not kart.is_on_ground())
	assert_bool(airborne).override_failure_message("le kart n'a pas quitté le sol après la rampe").is_true()
	assert_float(highest).is_greater(1.0)
#@ 4+


func test_le_kart_se_pose_sur_l_ile_au_depart() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	var kart := main.get_node("Kart") as Kart
	kart.input = null
	for _frame: int in 120:
		await get_tree().physics_frame
	assert_bool(kart.is_on_ground()).is_true()
	assert_float(kart.global_position.distance_to(Vector3(4.8399, 4.47262, -5.20099))).is_less(2.0)
#@ 6+


func test_la_position_du_kart_est_recopiee_pour_les_shaders() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	var kart := main.get_node("Kart") as Kart
	for _frame: int in 3:
		await get_tree().physics_frame
	assert_float(GameState.player_position.distance_to(kart.global_position)).is_less(0.5)
#@ 9+


func test_l_ocean_suit_le_kart() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	var kart := main.get_node("Kart") as Kart
	for _frame: int in 3:
		await get_tree().physics_frame
	var ocean := main.get_node("Island/Ocean") as Ocean
	assert_float(ocean.water_waves.texture_offset.distance_to(kart.global_position)).is_less(0.5)
#@ 11+


func test_la_meteo_mouille_les_shaders_et_les_roues() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	for _frame: int in 3:
		await get_tree().physics_frame
	var weather: Weather = main.get("weather")
	assert_float(GameState.rain_intensity).is_equal(weather.intensity)
	assert_float(GameState.rain_wetness).is_equal_approx(weather.wetness, 0.0001)
	assert_float((main.get_node("Kart/WheelEffects") as WheelSplashEffects).road_wetness).is_equal_approx(
		weather.wetness, 0.0001)
	assert_float((main.get_node("Rain") as RainView).intensity).is_equal(weather.intensity)


func test_l_orage_lance_des_eclairs_sur_le_kart() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	var stormy := (main.get("weather_settings") as WeatherSettings).duplicate() as WeatherSettings
	stormy.lightning_interval_min = 0.1
	stormy.lightning_interval_max = 0.2
	main.set("weather_settings", stormy)
	add_child(main)
	var struck := false
	for _frame: int in 30:
		await get_tree().physics_frame
		for child: Node in main.get_children():
			var strike := child as LightningStrike
			if strike != null and strike.target == main.get_node("Kart"):
				struck = true
	assert_bool(struck).is_true()
#@ 3+


func test_la_camera_suit_le_kart() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	var kart := main.get_node("Kart") as Kart
	var camera := main.get_node("FollowCamera/SpringArm/Camera3D") as Camera3D
	kart.input = null
	kart.commands.throttle = 1.0
	for _frame: int in 120:
		await get_tree().physics_frame
	await get_tree().process_frame
	assert_bool(camera.current).is_true()
	assert_float(camera.global_position.distance_to(kart.global_position)).is_less(6.0)
	assert_float(kart.forward_speed()).is_greater(5.0)
#@ all
