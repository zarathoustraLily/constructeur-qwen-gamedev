extends GdUnitTestSuite
## Règles du filtrage du stick et des gâchettes : sous la zone morte, zéro ; au bord de la zone, une valeur qui part
## de zéro ; à fond, une longueur de un ; la direction ne change jamais ; un stick lu sur des actions est filtré de
## la même façon.

const DEADZONE: float = 0.2


func after_test() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(action)


func test_sous_la_zone_morte_le_stick_vaut_zero() -> void:
	assert_vector(StickFilter.radial(Vector2(0.1, 0.1), DEADZONE)).is_equal(Vector2.ZERO)
	assert_vector(StickFilter.radial(Vector2(0.19, 0.0), DEADZONE)).is_equal(Vector2.ZERO)


func test_juste_apres_la_zone_morte_la_valeur_part_de_zero() -> void:
	assert_float(StickFilter.radial(Vector2(0.21, 0.0), DEADZONE).length()).is_less(0.02)


func test_a_fond_la_longueur_vaut_un_dans_la_meme_direction() -> void:
	var raw: Vector2 = Vector2(0.6, 0.8)
	var filtered: Vector2 = StickFilter.radial(raw, DEADZONE)
	assert_float(filtered.length()).is_equal_approx(1.0, 0.0001)
	assert_float(filtered.normalized().dot(raw.normalized())).is_equal_approx(1.0, 0.0001)


func test_a_mi_course_la_valeur_est_remise_a_l_echelle() -> void:
	assert_float(StickFilter.radial(Vector2(0.6, 0.0), DEADZONE).x).is_equal_approx(0.5, 0.0001)


func test_une_course_au_dela_de_un_est_bornee() -> void:
	assert_float(StickFilter.radial(Vector2(1.2, 0.0), DEADZONE).length()).is_equal_approx(1.0, 0.0001)


func test_la_gachette_a_sa_zone_morte() -> void:
	assert_float(StickFilter.trigger(0.05, 0.1)).is_equal(0.0)
	assert_float(StickFilter.trigger(0.55, 0.1)).is_equal_approx(0.5, 0.0001)
	assert_float(StickFilter.trigger(1.0, 0.1)).is_equal_approx(1.0, 0.0001)


func test_le_stick_lu_sur_des_actions_est_filtre() -> void:
	Input.action_press(&"move_right", 0.6)
	var stick: Vector2 = StickFilter.from_actions(&"move_left", &"move_right", &"move_up", &"move_down", DEADZONE)
	assert_float(stick.x).is_equal_approx(0.5, 0.0001)
	assert_float(stick.y).is_equal_approx(0.0, 0.0001)
