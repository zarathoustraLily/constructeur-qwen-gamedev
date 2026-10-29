extends GdUnitTestSuite
## Règles de la jauge du boss : cachée au départ ; montrée à son nom ; sa jauge suit la vie qu'on lui donne.

const BOSS_BAR := preload("res://4_ui/hud/boss_bar/boss_bar.tscn")


func _boss_bar() -> BossBar:
	var boss_bar: BossBar = auto_free(BOSS_BAR.instantiate()) as BossBar
	add_child(boss_bar)
	return boss_bar


func test_cachee_au_depart() -> void:
	assert_bool(_boss_bar().visible).is_false()


func test_montree_a_son_nom() -> void:
	var boss_bar: BossBar = _boss_bar()
	boss_bar.reveal("Le Gardien du Comptoir")
	assert_bool(boss_bar.visible).is_true()
	assert_str(boss_bar.shown_name()).is_equal("Le Gardien du Comptoir")


func test_sa_jauge_suit_la_vie() -> void:
	var boss_bar: BossBar = _boss_bar()
	boss_bar.bar.set_values(750.0, 1500.0)
	assert_float(boss_bar.bar.ratio).is_equal_approx(0.5, 0.0001)
