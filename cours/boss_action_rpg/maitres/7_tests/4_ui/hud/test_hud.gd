extends GdUnitTestSuite
## Règles de l'interface : ses jauges prennent la traîne de ses réglages ; branchée sur des composants, chaque jauge
## part de leur valeur et suit leurs changements (un coup, un soin, une dépense d'endurance, un tir qui chauffe, une
## fiole bue) ; la jauge du boss se montre à son nom ; l'écran de chute affiche le mot des réglages.

const HUD := preload("res://4_ui/hud/hud.tscn")
const SETTINGS := preload("res://5_data/ui/hud.tres")

var _hud: Hud


func before_test() -> void:
	_hud = HUD.instantiate() as Hud
	_hud.settings = SETTINGS
	add_child(auto_free(_hud))


func _health(maximum: float) -> HealthComponent:
	var settings: HealthSettings = HealthSettings.new()
	settings.max_health = maximum
	settings.invincibility_time = 0.0
	var health: HealthComponent = auto_free(HealthComponent.new())
	health.settings = settings
	add_child(health)
	return health


func test_les_jauges_prennent_la_traine_des_reglages() -> void:
	assert_float(_hud.health_bar.trail_delay).is_equal(SETTINGS.trail_delay)
	assert_float(_hud.boss_bar.bar.trail_speed).is_equal(SETTINGS.trail_speed)


func test_la_vie_part_de_sa_valeur_et_suit_coups_et_soins() -> void:
	var health: HealthComponent = _health(100.0)
	health.take_damage(20.0)
	_hud.bind_health(health)
	assert_float(_hud.health_bar.ratio).is_equal_approx(0.8, 0.0001)
	health.take_damage(30.0)
	assert_float(_hud.health_bar.ratio).is_equal_approx(0.5, 0.0001)
	health.heal(10.0)
	assert_float(_hud.health_bar.ratio).is_equal_approx(0.6, 0.0001)


func test_l_endurance_la_chaleur_et_les_fioles_suivent_leurs_composants() -> void:
	var stamina: StaminaComponent = auto_free(StaminaComponent.new())
	stamina.settings = preload("res://5_data/hero/hero_stamina.tres")
	add_child(stamina)
	_hud.bind_stamina(stamina)
	stamina.spend(25.0)
	assert_float(_hud.stamina_bar.ratio).is_equal_approx(0.75, 0.0001)
	var heat: HeatComponent = auto_free(HeatComponent.new())
	heat.settings = preload("res://5_data/hero/hero_gun_heat.tres")
	add_child(heat)
	_hud.bind_heat(heat)
	assert_float(_hud.heat_bar.ratio).is_equal(0.0)
	assert_float(_hud.heat_bar.trail_ratio).is_equal(0.0)
	heat.add(50.0)
	assert_float(_hud.heat_bar.ratio).is_equal_approx(0.5, 0.0001)
	var flasks: FlaskComponent = auto_free(FlaskComponent.new())
	add_child(flasks)
	flasks.fill(3)
	_hud.bind_flasks(flasks)
	flasks.use()
	assert_int(_hud.flasks.charges).is_equal(2)


func test_la_jauge_du_boss_se_montre_a_son_nom() -> void:
	var health: HealthComponent = _health(1500.0)
	_hud.bind_boss(health)
	assert_bool(_hud.boss_bar.visible).is_true()
	assert_str(_hud.boss_bar.shown_name()).is_equal(SETTINGS.boss_name)
	health.take_damage(150.0)
	assert_float(_hud.boss_bar.bar.ratio).is_equal_approx(0.9, 0.0001)


func test_l_ecran_de_chute_affiche_le_mot_des_reglages() -> void:
	_hud.show_defeat()
	assert_bool(_hud.defeat.visible).is_true()
	assert_str(_hud.defeat.shown_text()).is_equal(SETTINGS.defeat_text)
