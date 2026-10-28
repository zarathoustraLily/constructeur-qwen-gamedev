extends GdUnitTestSuite
## Règles des gerbes de particules : le dégradé va de la couleur de naissance à celle de mort ; la taille part de un
## et finit à zéro ; les étincelles partent vers le haut dans leur cône, à leur vitesse, et retombent ; la poussière
## s'étale à plat ; un émetteur lâche tout d'un coup, une seule fois, et attend qu'on le lance.

const SETTINGS := preload("res://5_data/vfx/vfx.tres")


func test_le_degrade_va_de_la_naissance_a_la_mort() -> void:
	var ramp: GradientTexture1D = ParticleRecipes.color_ramp(SETTINGS.spark_colors)
	assert_that(ramp.gradient.sample(0.0)).is_equal(SETTINGS.spark_colors[0])
	assert_that(ramp.gradient.sample(1.0)).is_equal(SETTINGS.spark_colors[1])
	assert_array(Array(ramp.gradient.offsets)).is_equal([0.0, 1.0])


func test_un_degrade_de_trois_couleurs_est_regulier() -> void:
	var ramp: GradientTexture1D = ParticleRecipes.color_ramp(PackedColorArray([Color.RED, Color.GREEN, Color.BLUE]))
	assert_array(Array(ramp.gradient.offsets)).is_equal([0.0, 0.5, 1.0])


func test_la_taille_part_de_un_et_finit_a_zero() -> void:
	var curve: Curve = ParticleRecipes.shrink_curve().curve
	assert_float(curve.sample(0.0)).is_equal_approx(1.0, 0.0001)
	assert_float(curve.sample(1.0)).is_equal_approx(0.0, 0.0001)


func test_les_etincelles_partent_vers_le_haut_et_retombent() -> void:
	var material: ParticleProcessMaterial = ParticleRecipes.sparks_material(SETTINGS)
	assert_vector(material.direction).is_equal(Vector3.UP)
	assert_float(material.spread).is_equal(SETTINGS.spark_spread)
	assert_float(material.initial_velocity_min).is_equal(SETTINGS.spark_speed.x)
	assert_float(material.initial_velocity_max).is_equal(SETTINGS.spark_speed.y)
	assert_float(material.gravity.y).is_less(0.0)
	assert_object(material.scale_curve).is_not_null()
	assert_object(material.color_ramp).is_not_null()


func test_la_poussiere_s_etale_a_plat() -> void:
	var material: ParticleProcessMaterial = ParticleRecipes.dust_material()
	assert_float(material.flatness).is_equal(1.0)
	assert_float(material.spread).is_equal(180.0)
	assert_float(material.direction.y).is_equal(0.0)


func test_un_emetteur_lache_tout_d_un_coup_une_seule_fois() -> void:
	var particles: GPUParticles3D = auto_free(ParticleRecipes.burst(ParticleRecipes.dust_material(), 12, 0.9))
	assert_int(particles.amount).is_equal(12)
	assert_float(particles.lifetime).is_equal(0.9)
	assert_bool(particles.one_shot).is_true()
	assert_float(particles.explosiveness).is_equal(1.0)
	assert_bool(particles.emitting).is_false()
	assert_object(particles.draw_pass_1).is_not_null()
