extends GdUnitTestSuite
## Règles du composant de recul : les poussées s'additionnent, le recul est borné à max_knockback, il s'amortit
## à chaque image physique, et il est actif au-dessus de 1 m/s.


func _knockback() -> KnockbackComponent:
	return auto_free(KnockbackComponent.new())


func test_les_poussees_s_additionnent() -> void:
	var knockback := _knockback()
	knockback.add_knockback(Vector3(3.0, 0.0, 0.0))
	knockback.add_knockback(Vector3(0.0, 0.0, 4.0))
	assert_vector(knockback.magnitude).is_equal(Vector3(3.0, 0.0, 4.0))


func test_le_recul_est_borne_a_max_knockback() -> void:
	var knockback := _knockback()
	knockback.add_knockback(Vector3(100.0, 0.0, 0.0))
	assert_float(knockback.magnitude.length()).is_equal_approx(knockback.max_knockback, 0.001)


func test_le_recul_s_amortit_a_chaque_image_physique() -> void:
	var knockback := _knockback()
	add_child(knockback)
	knockback.add_knockback(Vector3(10.0, 0.0, 0.0))
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_float(knockback.magnitude.x).is_less(10.0)
	assert_float(knockback.magnitude.x).is_greater(0.0)


func test_il_est_actif_au_dessus_d_un_metre_par_seconde() -> void:
	var knockback := _knockback()
	knockback.add_knockback(Vector3(0.9, 0.0, 0.0))
	assert_bool(knockback.is_active()).is_false()
	knockback.add_knockback(Vector3(0.2, 0.0, 0.0))
	assert_bool(knockback.is_active()).is_true()
