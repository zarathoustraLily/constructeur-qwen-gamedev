extends GdUnitTestSuite
## Règles du corps flottant, sur une surface d'eau plate à hauteur 0 : il repère ses capteurs, sait combien
## sont immergés, est freiné dans l'eau, et la poussée ralentit sa chute ; elle suit les multiplicateurs et la
## profondeur, et un capteur décalé fait pencher le corps.

const SurfaceTemoin := preload("res://7_tests/1_core/water/surface_temoin.gd")


func before_test() -> void:
	add_child(auto_free(SurfaceTemoin.new()))


func _corps(hauteurs_des_capteurs: Array[float], position: Vector3 = Vector3.ZERO) -> BuoyantBody3D:
	var corps: BuoyantBody3D = auto_free(BuoyantBody3D.new())
	for y: float in hauteurs_des_capteurs:
		var capteur := WaterBuoyancySensor.new()
		capteur.position.y = y
		corps.add_child(capteur)
	corps.position = position
	add_child(corps)
	return corps


## Un pas de flottaison, sans laisser le moteur physique avancer : les capteurs lisent la surface, puis le
## corps compte ceux qui sont immergés.
func _un_pas(corps: BuoyantBody3D) -> void:
	corps.gravity_scale = 0.0
	for capteur: WaterBuoyancySensor in corps._buoyancy_sensors:
		capteur._physics_process(1.0 / 60.0)
	corps._physics_process(1.0 / 60.0)


func test_il_repere_tous_ses_capteurs() -> void:
	assert_int(_corps([-1.0, 0.0, 1.0])._buoyancy_sensors.size()).is_equal(3)


func test_immerge_des_qu_un_capteur_est_sous_la_surface() -> void:
	var corps := _corps([-0.5, 0.5])
	_un_pas(corps)
	assert_bool(corps.submerged).is_true()
	assert_int(corps.submerged_probes).is_equal(1)


func test_hors_de_l_eau_quand_tous_les_capteurs_sont_au_dessus() -> void:
	var corps := _corps([0.5, 1.0])
	_un_pas(corps)
	assert_bool(corps.submerged).is_false()
	assert_int(corps.submerged_probes).is_equal(0)


func test_immerge_il_est_freine() -> void:
	var corps := _corps([-0.5])
	_un_pas(corps)
	corps.linear_velocity = Vector3(10, 0, 0)
	corps.angular_velocity = Vector3(0, 10, 0)
	corps._integrate_forces(null)
	assert_vector(corps.linear_velocity).is_equal_approx(Vector3(10, 0, 0) * (1.0 - corps.submerged_drag_linear), Vector3.ONE * 0.0001)
	assert_vector(corps.angular_velocity).is_equal_approx(Vector3(0, 10, 0) * (1.0 - corps.submerged_drag_angular), Vector3.ONE * 0.0001)


func test_hors_de_l_eau_il_n_est_pas_freine() -> void:
	var corps := _corps([0.5])
	_un_pas(corps)
	corps.linear_velocity = Vector3(10, 0, 0)
	corps._integrate_forces(null)
	assert_vector(corps.linear_velocity).is_equal(Vector3(10, 0, 0))


func test_la_poussee_ralentit_la_chute_dans_l_eau() -> void:
	var flottant := _corps([0.0], Vector3(0, -1, 0))
	var lest := _corps([0.0], Vector3(20, -1, 0))
	lest.buoyancy_multiplier = 0.0
	for _frame: int in 30:
		await get_tree().physics_frame
	assert_float(flottant.global_position.y).is_greater(lest.global_position.y)


func test_un_capteur_juste_a_la_surface_ne_compte_pas() -> void:
	var corps := _corps([0.0])
	_un_pas(corps)
	assert_bool(corps.submerged).is_false()


## Corps flottant sans gravité, avec une forme (donc une inertie), un capteur par position donnée.
func _corps_libre(position: Vector3, capteurs: Array[Vector3]) -> BuoyantBody3D:
	var corps: BuoyantBody3D = auto_free(BuoyantBody3D.new())
	corps.gravity_scale = 0.0
	corps.can_sleep = false
	var forme := CollisionShape3D.new()
	forme.shape = SphereShape3D.new()
	corps.add_child(forme)
	for p: Vector3 in capteurs:
		var capteur := WaterBuoyancySensor.new()
		capteur.position = p
		corps.add_child(capteur)
	corps.position = position
	add_child(corps)
	return corps


func _pas_de_physique(nombre: int) -> void:
	for _frame: int in nombre:
		await get_tree().physics_frame


func test_la_poussee_double_avec_le_multiplicateur_du_corps() -> void:
	var temoin := _corps_libre(Vector3(0, -2, 0), [Vector3.ZERO])
	var double := _corps_libre(Vector3(10, -2, 0), [Vector3.ZERO])
	double.buoyancy_multiplier = temoin.buoyancy_multiplier * 2.0
	await _pas_de_physique(3)
	assert_float(temoin.linear_velocity.y).is_greater(0.0)
	assert_float(double.linear_velocity.y / temoin.linear_velocity.y).is_equal_approx(2.0, 0.01)


func test_la_poussee_double_avec_le_multiplicateur_du_capteur() -> void:
	var temoin := _corps_libre(Vector3(0, -2, 0), [Vector3.ZERO])
	var double := _corps_libre(Vector3(10, -2, 0), [Vector3.ZERO])
	var capteur: WaterBuoyancySensor = double._buoyancy_sensors[0]
	capteur.buoyancy_multiplier = 2.0
	await _pas_de_physique(3)
	assert_float(double.linear_velocity.y / temoin.linear_velocity.y).is_equal_approx(2.0, 0.01)


func test_la_poussee_suit_la_profondeur_a_la_puissance_buoyancy_power() -> void:
	var profond := _corps_libre(Vector3(0, -2, 0), [Vector3.ZERO])
	var peu_profond := _corps_libre(Vector3(10, -1, 0), [Vector3.ZERO])
	await _pas_de_physique(3)
	var attendu := pow(0.5, profond.buoyancy_power)
	assert_float(peu_profond.linear_velocity.y / profond.linear_velocity.y).is_equal_approx(attendu, attendu * 0.02)


func test_un_capteur_decale_fait_pencher_le_corps_de_la_meme_facon_ou_qu_il_soit() -> void:
	var ici := _corps_libre(Vector3(0, -2, 0), [Vector3(1, 0, 0)])
	var loin := _corps_libre(Vector3(40, -2, 0), [Vector3(1, 0, 0)])
	await _pas_de_physique(3)
	assert_float(ici.angular_velocity.z).is_greater(0.0)
	assert_vector(loin.angular_velocity).is_equal_approx(ici.angular_velocity, Vector3.ONE * absf(ici.angular_velocity.z) * 0.02)
