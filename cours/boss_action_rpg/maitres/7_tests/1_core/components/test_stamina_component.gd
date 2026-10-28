extends GdUnitTestSuite
## Règles de l'endurance : pleine au départ ; une dépense la vide sans passer sous zéro, et on peut agir tant qu'il en
## reste ; elle remonte après son délai, avec le temps qui reste, sans dépasser le maximum ; chaque dépense relance le
## délai ; chaque changement s'annonce.

const SETTINGS := preload("res://5_data/hero/hero_stamina.tres")

var _stamina: StaminaComponent
var _changes: Array[Vector2] = []


func before_test() -> void:
	_stamina = auto_free(StaminaComponent.new())
	_stamina.settings = SETTINGS
	add_child(_stamina)
	_changes.clear()


func _on_changed(current: float, maximum: float) -> void:
	_changes.append(Vector2(current, maximum))


func test_au_depart_elle_est_pleine() -> void:
	assert_float(_stamina.stamina).is_equal(SETTINGS.max_stamina)
	assert_float(_stamina.ratio()).is_equal(1.0)


func test_une_depense_la_vide_sans_passer_sous_zero() -> void:
	_stamina.spend(30.0)
	assert_float(_stamina.stamina).is_equal(SETTINGS.max_stamina - 30.0)
	_stamina.spend(SETTINGS.max_stamina - 40.0)
	assert_bool(_stamina.can_spend()).is_true()
	_stamina.spend(25.0)
	assert_float(_stamina.stamina).is_equal(0.0)
	assert_bool(_stamina.can_spend()).is_false()


func test_elle_remonte_apres_son_delai_sans_depasser_le_maximum() -> void:
	_stamina.spend(50.0)
	_stamina.tick(SETTINGS.regen_delay - 0.1)
	assert_float(_stamina.stamina).is_equal(SETTINGS.max_stamina - 50.0)
	_stamina.tick(0.6)
	assert_float(_stamina.stamina).is_equal_approx(SETTINGS.max_stamina - 50.0 + SETTINGS.regen_rate * 0.5, 0.001)
	_stamina.tick(10.0)
	assert_float(_stamina.stamina).is_equal(SETTINGS.max_stamina)


func test_chaque_depense_relance_le_delai() -> void:
	_stamina.spend(10.0)
	_stamina.tick(SETTINGS.regen_delay * 0.8)
	_stamina.spend(10.0)
	_stamina.tick(SETTINGS.regen_delay * 0.8)
	assert_float(_stamina.stamina).is_equal(SETTINGS.max_stamina - 20.0)


func test_chaque_changement_s_annonce() -> void:
	_stamina.changed.connect(_on_changed)
	_stamina.spend(25.0)
	_stamina.spend(0.0)
	assert_array(_changes).is_equal([Vector2(SETTINGS.max_stamina - 25.0, SETTINGS.max_stamina)])
