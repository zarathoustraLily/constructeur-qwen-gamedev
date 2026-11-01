extends GdUnitTestSuite
## Règles de la bougie : elle brûle au départ, flamme et lumière visibles ; la souffler les éteint et change l'invite ;
## la rallumer les rend ; sa lumière vacille sans sortir de sa marge ; elle arrête les corps.

const CANDLE := preload("res://3_entities/props/candle/candle.tscn")


func _candle() -> Candle:
	var candle: Candle = auto_free(CANDLE.instantiate())
	add_child(candle)
	return candle


func test_elle_brule_au_depart() -> void:
	var candle: Candle = _candle()
	assert_bool(candle.lit).is_true()
	assert_bool((candle.get_node("Flame") as Node3D).visible).is_true()
	assert_bool((candle.get_node("Light") as Node3D).visible).is_true()


func test_la_souffler_l_eteint_et_change_l_invite() -> void:
	var candle: Candle = _candle()
	(candle.get_node("Hand") as Interactable).use()
	assert_bool(candle.lit).is_false()
	assert_bool((candle.get_node("Flame") as Node3D).visible).is_false()
	assert_bool((candle.get_node("Light") as Node3D).visible).is_false()
	assert_str((candle.get_node("Hand") as Interactable).prompt).is_equal(candle.settings.light_prompt)


func test_la_rallumer_rend_sa_flamme() -> void:
	var candle: Candle = _candle()
	candle.toggle()
	candle.toggle()
	assert_bool(candle.lit).is_true()
	assert_bool((candle.get_node("Flame") as Node3D).visible).is_true()
	assert_str((candle.get_node("Hand") as Interactable).prompt).is_equal(candle.settings.blow_prompt)


func test_sa_lumiere_vacille_sans_sortir_de_sa_marge() -> void:
	var candle: Candle = _candle()
	var low: float = INF
	var high: float = 0.0
	for i: int in 600:
		var energy: float = candle.energy_at(i / 60.0)
		low = minf(low, energy)
		high = maxf(high, energy)
	var reach: float = candle.settings.energy * candle.settings.flicker
	assert_float(high - low).is_greater(reach * 0.5)
	assert_float(low).is_greater_equal(candle.settings.energy - reach)
	assert_float(high).is_less_equal(candle.settings.energy + reach)


func test_elle_arrete_les_corps() -> void:
	var candle: Candle = _candle()
	assert_bool(Layers.has((candle.get_node("Body") as StaticBody3D).collision_layer, Layers.WORLD)).is_true()
