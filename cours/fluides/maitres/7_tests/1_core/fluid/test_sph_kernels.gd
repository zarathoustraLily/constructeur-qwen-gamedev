extends GdUnitTestSuite
## Règles des noyaux de SPH : tous s'annulent à la portée et au-delà ; le noyau de densité intègre à 1 sur le disque et décroît avec la
## distance ; le noyau de pression ne s'annule pas au contact ; le noyau de viscosité reste positif.

const RADIUS := 1.5


func test_tous_s_annulent_a_la_portee_et_au_dela() -> void:
	assert_float(SphKernels.density_weight(RADIUS * RADIUS, RADIUS)).is_equal(0.0)
	assert_float(SphKernels.density_weight(9.0, RADIUS)).is_equal(0.0)
	assert_float(SphKernels.pressure_slope(RADIUS, RADIUS)).is_equal(0.0)
	assert_float(SphKernels.pressure_slope(3.0, RADIUS)).is_equal(0.0)
	assert_float(SphKernels.viscosity_curve(RADIUS, RADIUS)).is_equal(0.0)
	assert_float(SphKernels.viscosity_curve(3.0, RADIUS)).is_equal(0.0)


func test_le_noyau_de_densite_integre_a_un_sur_le_disque() -> void:
	var sum: float = 0.0
	var cell: float = 0.02
	var steps: int = ceili(RADIUS / cell)
	for y: int in range(-steps, steps + 1):
		for x: int in range(-steps, steps + 1):
			sum += SphKernels.density_weight(Vector2(x, y).length_squared() * cell * cell, RADIUS) * cell * cell
	assert_float(sum).is_equal_approx(1.0, 0.01)


func test_le_noyau_de_densite_decroit_avec_la_distance() -> void:
	assert_float(SphKernels.density_weight(0.1, RADIUS)).is_greater(SphKernels.density_weight(1.0, RADIUS))
	assert_float(SphKernels.density_weight(1.0, RADIUS)).is_greater(0.0)


func test_le_noyau_de_pression_ne_s_annule_pas_au_contact() -> void:
	assert_float(SphKernels.pressure_slope(0.0, RADIUS)).is_less(SphKernels.pressure_slope(0.5, RADIUS))
	assert_float(SphKernels.pressure_slope(0.5, RADIUS)).is_less(0.0)


func test_le_noyau_de_viscosite_reste_positif_et_grandit_de_pres() -> void:
	assert_float(SphKernels.viscosity_curve(1.0, RADIUS)).is_greater(0.0)
	assert_float(SphKernels.viscosity_curve(0.2, RADIUS)).is_greater(SphKernels.viscosity_curve(1.0, RADIUS))
