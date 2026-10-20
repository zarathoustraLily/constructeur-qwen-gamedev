extends GdUnitTestSuite
## Règles de conduite du kart : vitesse de pointe, boost, marche arrière, frein, durée du boost,
## boost en fin de dérapage. Le kart est piloté pas à pas, sans laisser tourner le moteur.

const SCENE_KART := "res://3_entities/kart/kart.tscn"
const PAS := 1.0 / 60.0

var _kart: Kart


func before_test() -> void:
	_kart = auto_free(load(SCENE_KART).instantiate())
	_kart.position = Vector3(0, 50, 0)
	add_child(_kart)
	_kart.set_process(false)
	_kart.set_physics_process(false)


func _moteur(secondes: float) -> void:
	for i in int(secondes / PAS):
		_kart._apply_car_engine_force(PAS)


func _vitesse() -> float:
	return _kart.get_horizontal_velocity().length()


func test_en_ligne_droite_la_vitesse_plafonne_a_la_vitesse_de_pointe() -> void:
	_kart.wish_acceleration = 1.0
	_moteur(10.0)
	assert_float(_vitesse()).is_between(_kart.top_speed * 0.95, _kart.top_speed + _kart.acceleration * PAS)


func test_le_kart_avance_vers_l_avant() -> void:
	_kart.wish_acceleration = 1.0
	_moteur(1.0)
	assert_float(_kart.velocity.z).is_less(0.0)


func test_le_boost_depasse_la_vitesse_de_pointe_jusqu_a_la_vitesse_de_boost() -> void:
	_kart.wish_acceleration = 1.0
	_kart.boost_timer = 100.0
	_moteur(10.0)
	assert_float(_vitesse()).is_greater(_kart.top_speed + 1.0)
	assert_float(_vitesse()).is_less_equal(_kart.boost_speed + _kart.boost_acceleration * PAS)


func test_la_marche_arriere_plafonne_a_sa_propre_vitesse() -> void:
	_kart.wish_acceleration = -1.0
	_moteur(10.0)
	assert_float(_kart.velocity.z).is_greater(0.0)
	assert_float(_vitesse()).is_between(_kart.top_reverse_speed * 0.95, _kart.top_reverse_speed + _kart.acceleration * PAS)


func test_freiner_arrete_plus_vite_que_rouler_en_roue_libre() -> void:
	_kart.velocity = Vector3(0, 0, -15)
	_moteur(5.0)
	var roue_libre := _vitesse()
	_kart.velocity = Vector3(0, 0, -15)
	_kart.wish_break = true
	_moteur(5.0)
	assert_float(_vitesse()).is_less(roue_libre * 0.8)


func test_un_boost_garde_la_plus_longue_duree() -> void:
	_kart.set_boost(2.0)
	assert_float(_kart.boost_timer).is_equal(2.0)
	_kart.set_boost(1.0)
	assert_float(_kart.boost_timer).is_equal(2.0)


func test_le_boost_s_epuise_avec_le_temps() -> void:
	_kart.set_boost(0.5)
	_kart._process(0.3)
	assert_float(_kart.boost_timer).is_equal_approx(0.2, 0.0001)
	_kart._process(0.3)
	assert_float(_kart.boost_timer).is_less_equal(0.0)


func test_finir_un_derapage_de_niveau_2_donne_une_demi_seconde_de_boost() -> void:
	_kart._set_drifing_stage(2)
	_kart._process(PAS)
	assert_float(_kart.boost_timer).is_equal_approx(0.5 - PAS, 0.0001)
	assert_int(_kart.drift_stage).is_equal(0)


func test_finir_un_derapage_de_niveau_3_donne_une_seconde_de_boost() -> void:
	_kart._set_drifing_stage(3)
	_kart._process(PAS)
	assert_float(_kart.boost_timer).is_equal_approx(1.0 - PAS, 0.0001)


func test_finir_un_derapage_de_niveau_1_ne_donne_rien() -> void:
	_kart._set_drifing_stage(1)
	_kart._process(PAS)
	assert_float(_kart.boost_timer).is_equal(0.0)


func after_test() -> void:
	for action: String in ["move_forward", "move_backward", "move_left", "move_right", "move_jump", "move_brake"]:
		Input.action_release(action)


## Pose le kart sur l'eau : son capteur de flottaison est sous la surface (hauteur 0, sans océan).
func _sur_l_eau() -> void:
	_kart.global_position = Vector3(0, -1, 0)
	assert_bool(_kart.is_on_ground()).is_true()


## Rotation du kart autour de la verticale pendant `secondes`, à `vitesse` vers l'avant.
func _virage(vitesse: float, braquage: float, secondes: float = 0.25) -> float:
	var depart := _kart.rotation.y
	for i in int(secondes / PAS):
		_kart.velocity = -_kart.global_transform.basis.z * vitesse
		_kart.wish_steering = braquage
		_kart._apply_steering(PAS)
	return _kart.rotation.y - depart


func test_braquer_a_droite_tourne_le_kart_vers_la_droite() -> void:
	_sur_l_eau()
	assert_float(_virage(10.0, 1.0)).is_less(0.0)


func test_braquer_a_gauche_tourne_le_kart_vers_la_gauche() -> void:
	_sur_l_eau()
	assert_float(_virage(10.0, -1.0)).is_greater(0.0)


func test_a_l_arret_le_kart_ne_tourne_pas() -> void:
	_sur_l_eau()
	assert_float(_virage(0.0, 1.0)).is_equal(0.0)


func test_en_freinant_a_l_arret_le_kart_tourne_sur_place() -> void:
	_sur_l_eau()
	_kart.wish_break = true
	assert_float(_virage(0.0, 1.0)).is_less(0.0)


func test_en_l_air_le_kart_tourne_meme_sans_vitesse() -> void:
	assert_bool(_kart.is_on_ground()).is_false()
	assert_float(_virage(0.0, 1.0)).is_less(0.0)


func test_le_virage_est_plus_serre_a_basse_vitesse() -> void:
	_sur_l_eau()
	var lent := absf(_virage(5.0, 1.0, 0.1)) / 5.0
	_kart.rotation = Vector3.ZERO
	_kart.steering = 0.0
	var rapide := absf(_virage(20.0, 1.0, 0.1)) / 20.0
	assert_float(lent).is_greater(rapide)


func test_un_derapage_serre_le_virage() -> void:
	_sur_l_eau()
	var normal := absf(_virage(10.0, 1.0))
	_kart.rotation = Vector3.ZERO
	_kart.steering = 0.0
	_kart.wish_drift = true
	_kart.wish_drift_direction = 1.0
	assert_float(absf(_virage(10.0, 1.0))).is_greater(normal)


func test_le_braquage_s_etablit_progressivement() -> void:
	_sur_l_eau()
	_virage(10.0, 1.0, PAS)
	assert_float(_kart.steering).is_between(0.01, 0.99)
	_virage(10.0, 1.0, 0.5)
	assert_float(_kart.steering).is_equal_approx(1.0, 0.01)


func test_les_roues_recoivent_la_vitesse_du_kart() -> void:
	_sur_l_eau()
	_virage(10.0, 0.0, PAS)
	for roue in _kart.wheels:
		assert_float(roue.speed).is_equal_approx(10.0, 0.01)


func test_une_figure_en_l_air_donne_une_seconde_de_boost_a_l_atterrissage() -> void:
	_kart.wish_jump = true
	_kart._physics_process(PAS)
	assert_bool(_kart.has_tricked).is_true()
	assert_float(_kart.trick_timer).is_equal(_kart.trick_cooldown)
	_sur_l_eau()
	_kart._process(PAS)
	assert_bool(_kart.has_tricked).is_false()
	assert_float(_kart.boost_timer).is_equal_approx(1.0 - PAS, 0.0001)


func test_pas_de_figure_avant_la_fin_du_delai() -> void:
	_kart.trick_timer = 0.2
	_kart.wish_jump = true
	_kart._physics_process(PAS)
	assert_bool(_kart.has_tricked).is_false()


func test_sauter_donne_quatre_metres_par_seconde_vers_le_haut() -> void:
	_sur_l_eau()
	_kart._physics_process(PAS)
	var sans_saut := _kart.velocity.y
	_kart.global_position = Vector3(0, -1, 0)
	_kart.velocity = Vector3.ZERO
	_kart.in_water_timer = 0.0
	_kart.wish_jump = true
	_kart._physics_process(PAS)
	assert_float(_kart.velocity.y - sans_saut).is_equal_approx(4.0, 0.01)


func test_les_commandes_s_effacent_apres_chaque_pas_de_physique() -> void:
	_kart.wish_jump = true
	_kart.wish_steering = 1.0
	_kart.wish_acceleration = 1.0
	_kart.trick_timer = 1.0
	_kart._physics_process(PAS)
	assert_bool(_kart.wish_jump).is_false()
	assert_float(_kart.wish_steering).is_equal(0.0)
	assert_float(_kart.wish_acceleration).is_equal(0.0)


func test_en_l_air_la_gravite_est_double() -> void:
	_kart.velocity = Vector3.ZERO
	_kart._apply_air_force(PAS)
	assert_float(_kart.velocity.y).is_equal_approx(-2.0 * 9.81 * PAS, 0.0001)


func test_le_kart_ne_derive_pas_de_cote() -> void:
	_kart.velocity = Vector3(5, 0, -3)
	_kart._apply_air_force(PAS)
	assert_float(_kart.velocity.x).is_equal_approx(0.0, 0.0001)
	assert_float(_kart.velocity.z).is_equal_approx(-3.0, 0.0001)
	_sur_l_eau()
	_kart.velocity = Vector3(5, 0, -3)
	_kart._apply_car_engine_force(PAS)
	assert_float(_kart.velocity.x).is_equal_approx(0.0, 0.0001)


func test_dans_l_eau_le_kart_remonte_vers_la_surface() -> void:
	_sur_l_eau()
	_kart.velocity = Vector3.ZERO
	_kart._apply_water_force(PAS)
	assert_float(_kart.velocity.y).is_greater(0.0)
	assert_float(_kart.in_water_timer).is_equal_approx(PAS, 0.0001)


func test_apres_une_seconde_dans_l_eau_le_kart_colle_a_la_surface() -> void:
	_sur_l_eau()
	_kart.in_water_timer = 1.0
	_kart.velocity = Vector3(0, -3, 0)
	_kart._apply_water_force(PAS)
	assert_float(_kart.global_position.y).is_greater(-1.0)
	assert_float(_kart.velocity.y).is_greater(-3.0)


func test_hors_de_l_eau_le_temps_dans_l_eau_repart_a_zero() -> void:
	_kart.in_water_timer = 2.0
	_kart._apply_water_force(PAS)
	assert_float(_kart.in_water_timer).is_equal(0.0)


## Attend une nouvelle image : un saut relâché à la fin du test précédent, dans la même image,
## serait encore « tout juste relâché » et couperait le dérapage aussitôt commencé.
func _image_neuve() -> void:
	await get_tree().process_frame


func test_un_derapage_monte_de_niveau_avec_le_temps() -> void:
	_sur_l_eau()
	await _image_neuve()
	Input.action_press("move_forward")
	Input.action_press("move_right")
	Input.action_press("move_jump")
	_kart._process(PAS)
	assert_bool(_kart.wish_drift).is_true()
	assert_int(_kart.drift_stage).is_equal(1)
	await get_tree().process_frame
	for i in 9:
		_kart._process(0.1)
	assert_int(_kart.drift_stage).is_equal(2)
	for i in 22:
		_kart._process(0.1)
	assert_int(_kart.drift_stage).is_equal(3)


func test_relacher_le_saut_finit_le_derapage_et_donne_le_boost() -> void:
	_sur_l_eau()
	await _image_neuve()
	Input.action_press("move_forward")
	Input.action_press("move_right")
	Input.action_press("move_jump")
	_kart._process(PAS)
	await get_tree().process_frame
	for i in 31:
		_kart._process(0.1)
	Input.action_release("move_jump")
	_kart._process(PAS)
	assert_bool(_kart.wish_drift).is_false()
	assert_int(_kart.drift_stage).is_equal(0)
	assert_float(_kart.boost_timer).is_equal_approx(1.0 - PAS, 0.0001)


func test_quand_le_boost_s_epuise_ses_flammes_s_eteignent() -> void:
	var flammes: Array[GPUParticles3D] = _kart.particles_manager.boost_particles
	assert_array(flammes).is_not_empty()
	_kart.set_boost(0.2)
	assert_bool(flammes[0].emitting).is_true()
	_kart._process(0.3)
	assert_bool(flammes[0].emitting).is_false()
