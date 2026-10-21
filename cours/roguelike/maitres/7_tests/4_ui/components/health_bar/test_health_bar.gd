extends GdUnitTestSuite
## Règles de la barre de santé : pleine au départ, de la couleur demandée ; un coup fait tomber la barre de
## devant d'un coup, celle de derrière la rejoint en douceur ; vaincu, la barre s'efface et part ; sans santé à
## suivre, elle reste éteinte, sans erreur.

const BAR := preload("res://4_ui/components/health_bar/health_bar.tscn")

var _health: HealthComponent


func _bar() -> HealthBar:
	_health = auto_free(HealthComponent.new())
	_health.max_health = 40.0
	add_child(_health)
	var bar := BAR.instantiate() as HealthBar
	bar.health_component = _health
	bar.health_color = Color.ORANGE
	add_child(bar)
	return bar


func test_pleine_au_depart_et_de_la_couleur_demandee() -> void:
	var bar: HealthBar = auto_free(_bar())
	assert_float(bar.shown_percentage()).is_equal(100.0)
	var front := bar.get_node("SubViewport/FrontProgressBar") as ProgressBar
	assert_that((front.get_theme_stylebox(&"fill") as StyleBoxFlat).bg_color).is_equal(Color.ORANGE)


func test_un_coup_fait_tomber_la_barre_de_devant_celle_de_derriere_la_rejoint() -> void:
	var bar: HealthBar = auto_free(_bar())
	_health.take_damage(10.0)
	assert_float(bar.shown_percentage()).is_equal_approx(75.0, 0.01)
	var back := bar.get_node("SubViewport/HealthProgressBar") as ProgressBar
	for _frame: int in 30:
		await get_tree().process_frame
	assert_float(back.value).is_equal_approx(75.0, 0.01)


func test_vaincu_la_barre_s_efface_et_part() -> void:
	var bar := _bar()
	_health.take_damage(40.0)
	for _frame: int in 30:
		await get_tree().process_frame
	assert_bool(is_instance_valid(bar)).is_false()


func test_sans_sante_elle_reste_eteinte() -> void:
	var bar: HealthBar = auto_free(BAR.instantiate())
	add_child(bar)
	await get_tree().process_frame
	assert_object(bar.health_component).is_null()
