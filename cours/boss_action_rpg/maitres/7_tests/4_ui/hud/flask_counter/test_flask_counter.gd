extends GdUnitTestSuite
## Règles du compte des fioles : il affiche le nombre qui reste ; sans fiole, il s'éteint à moitié, et se rallume quand
## il en revient une.

const COUNTER := preload("res://4_ui/hud/flask_counter/flask_counter.tscn")


func _counter() -> FlaskCounter:
	var counter: FlaskCounter = auto_free(COUNTER.instantiate()) as FlaskCounter
	add_child(counter)
	return counter


func test_il_affiche_le_nombre_qui_reste() -> void:
	var counter: FlaskCounter = _counter()
	counter.set_charges(3, 3)
	assert_str((counter.get_node("Count") as Label).text).is_equal("3")
	assert_int(counter.charges).is_equal(3)


func test_sans_fiole_il_s_eteint_puis_se_rallume() -> void:
	var counter: FlaskCounter = _counter()
	counter.set_charges(0, 3)
	assert_float(counter.modulate.a).is_less(1.0)
	counter.set_charges(1, 3)
	assert_float(counter.modulate.a).is_equal(1.0)
