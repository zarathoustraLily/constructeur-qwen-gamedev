extends GdUnitTestSuite
## Règles des objets du circuit : une bouée est un corps flottant, avec ses capteurs ; un cône est un corps
## rigide ; tous deux sont sur la couche Interactables, que le kart ne heurte pas : il les pousse sans être
## arrêté.

const BUOY := preload("res://3_entities/interactables/buoy/buoy.tscn")
const CONE := preload("res://3_entities/interactables/traffic_cone/traffic_cone.tscn")
const KART := preload("res://3_entities/kart/kart.tscn")
const INTERACTABLES := 64


func test_une_bouee_flotte_par_ses_capteurs() -> void:
	var buoy: BuoyantBody3D = auto_free(BUOY.instantiate())
	add_child(buoy)
	assert_int(buoy.find_children("*", "WaterBuoyancySensor", false, false).size()).is_greater(0)
	assert_int(buoy.collision_layer).is_equal(INTERACTABLES)


func test_un_cone_est_un_corps_rigide_de_la_couche_interactables() -> void:
	var cone: RigidBody3D = auto_free(CONE.instantiate())
	assert_object(cone).is_not_null()
	assert_int(cone.collision_layer).is_equal(INTERACTABLES)


func test_le_kart_pousse_un_cone_sans_etre_arrete() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = 8
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child(auto_free(ground))
	var cone: RigidBody3D = auto_free(CONE.instantiate())
	cone.position = Vector3(0.0, 0.1, -12.0)
	add_child(cone)
	var kart: Kart = auto_free(KART.instantiate())
	kart.input = null
	kart.position = Vector3(0.0, 0.6, 0.0)
	add_child(kart)
	kart.commands.throttle = 1.0
	for _frame: int in 150:
		await get_tree().physics_frame
	assert_float(cone.global_position.distance_to(Vector3(0.0, 0.1, -12.0))).override_failure_message(
		"le cône n'a pas bougé").is_greater(1.0)
	assert_float(kart.global_position.z).override_failure_message("le kart a été arrêté").is_less(-14.0)
