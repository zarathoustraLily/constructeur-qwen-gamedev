extends GdUnitTestSuite
## Règles du véhicule : moteur, carrosserie, roues, traces, alignement au sol, choc.


func _vehicule(chemin: String = "res://scenes/vehicle.tscn") -> Vehicle:
	var v: Vehicle = auto_free(load(chemin).instantiate())
	add_child(v)
	return v


func test_position_du_vehicule_est_celle_du_modele() -> void:
	var v := _vehicule()
	v.vehicle_model.global_position = Vector3(3, 1, -2)
	assert_vector(v.get_vehicle_position()).is_equal_approx(Vector3(3, 1, -2), Vector3(0.0001, 0.0001, 0.0001))


func test_moteur_plus_fort_a_pleine_vitesse() -> void:
	var v := _vehicule()
	v.engine_sound.volume_db = -15.0
	v.linear_speed = 1.0
	v.input.z = 1.0
	v.effect_engine(0.2)
	# Cible : remap(1 + 0.5, 0, 1.5, -15, -5) = -5 ; lerp de -15 vers -5 à 1.0 → -5.
	assert_float(v.engine_sound.volume_db).is_equal_approx(-5.0, 0.0001)


func test_regime_moteur_monte_avec_l_accelerateur() -> void:
	var v := _vehicule()
	v.engine_sound.pitch_scale = 0.5
	v.linear_speed = 0.0
	v.input.z = 1.0
	v.effect_engine(0.5)
	# Cible : 0.5 + 0.2 ; lerp de 0.5 vers 0.7 à 1.0.
	assert_float(v.engine_sound.pitch_scale).is_equal_approx(0.7, 0.0001)


func test_ralenti_sans_accelerateur() -> void:
	var v := _vehicule()
	v.engine_sound.pitch_scale = 2.0
	v.linear_speed = 0.0
	v.input.z = 0.0
	v.effect_engine(0.5)
	assert_float(v.engine_sound.pitch_scale).is_equal_approx(0.5, 0.0001)


func test_carrosserie_penche_dans_les_virages() -> void:
	var v := _vehicule()
	v.input.x = 1.0
	v.linear_speed = 1.0
	v.effect_body(0.2)
	assert_float(v.calculated_lean).is_equal_approx(-0.2, 0.0001)
	assert_float(v.vehicle_body.rotation.z).is_equal_approx(-0.2, 0.0001)


func test_carrosserie_revient_en_place() -> void:
	var v := _vehicule()
	v.vehicle_body.position = Vector3(0, 0.1, 0)
	v.effect_body(0.2)
	assert_vector(v.vehicle_body.position).is_equal_approx(Vector3(0, 0.2, 0), Vector3(0.0001, 0.0001, 0.0001))


func test_roues_tournent_avec_l_acceleration() -> void:
	var v := _vehicule()
	v.acceleration = 0.3
	var avant: float = v.wheel_bl.rotation.x
	v.effect_wheels(0.016)
	assert_float(v.wheel_bl.rotation.x - avant).is_equal_approx(0.3, 0.0001)


func test_roues_avant_braquent() -> void:
	var v := _vehicule()
	v.input.x = 1.5
	v.effect_wheels(0.1)
	assert_float(v.wheel_fl.rotation.y).is_equal_approx(-1.0, 0.0001)
	assert_float(v.wheel_fr.rotation.y).is_equal_approx(-1.0, 0.0001)


func test_traces_en_derapage() -> void:
	var v := _vehicule()
	v.linear_speed = 1.0
	v.acceleration = 0.0
	v.effect_trails()
	assert_bool(v.trail_left.emitting).is_true()
	assert_bool(v.trail_right.emitting).is_true()


func test_pas_de_traces_en_ligne_droite() -> void:
	var v := _vehicule()
	v.linear_speed = 0.5
	v.acceleration = 0.5
	v.calculated_lean = 0.0
	v.effect_trails()
	assert_bool(v.trail_left.emitting).is_false()


func test_alignement_sur_la_normale() -> void:
	var v := _vehicule()
	var normale := Vector3(0, 1, 1).normalized()
	var x: Transform3D = v.align_with_y(Transform3D.IDENTITY, normale)
	assert_vector(x.basis.y).is_equal_approx(normale, Vector3(0.0001, 0.0001, 0.0001))
	assert_float(x.basis.x.dot(normale)).is_equal_approx(0.0, 0.0001)


func test_choc_plus_fort_avec_la_vitesse() -> void:
	var v := _vehicule()
	v.linear_velocity = v.vehicle_body.global_basis.z * 6.0
	v._on_sphere_body_entered(null)
	assert_float(v.impact_sound.volume_db).is_equal_approx(0.0, 0.0001)


func test_choc_leger_a_basse_vitesse() -> void:
	var v := _vehicule()
	v.linear_velocity = v.vehicle_body.global_basis.z * 3.0
	v._on_sphere_body_entered(null)
	assert_float(v.impact_sound.volume_db).is_equal_approx(-10.0, 0.0001)


func test_connexion_du_choc() -> void:
	var v := _vehicule()
	assert_bool(v.sphere.body_entered.is_connected(v._on_sphere_body_entered)).is_true()


func test_moto_penche_et_braque() -> void:
	var v := _vehicule("res://scenes/vehicle-motorcycle.tscn")
	v.input.x = 1.5
	v.linear_speed = 1.0
	v.effect_body(0.2)
	assert_float(v.calculated_lean).is_equal_approx(-0.3, 0.0001)
	v.effect_wheels(0.1)
	assert_float(v.wheel_front.rotation.y).is_equal_approx(-1.0, 0.0001)
	assert_float(v.fork.rotation.y).is_equal_approx(-0.5, 0.0001)


func test_moto_carrosserie_est_le_corps() -> void:
	var v := _vehicule("res://scenes/vehicle-motorcycle.tscn")
	assert_object(v.vehicle_body).is_same(v.get_node("Container/Model/motorcycle/body"))
