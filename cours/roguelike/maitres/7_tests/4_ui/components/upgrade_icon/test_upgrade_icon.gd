extends GdUnitTestSuite
## Règles de la carte d'amélioration : elle montre le titre et la description pour la cible ; un clic émet chosen
## avec son amélioration, sans rien modifier ; avec le focus, elle s'éclaire.

const ICON := preload("res://4_ui/components/upgrade_icon/upgrade_icon.tscn")
const TEMOIN := preload("res://7_tests/1_core/upgrades/cible_temoin.gd")
const DAMAGE := preload("res://5_data/upgrades/damage.tres")

var _icon: UpgradeIcon
var _target: Node


func before_test() -> void:
	_icon = auto_free(ICON.instantiate())
	add_child(_icon)
	_target = auto_free(TEMOIN.new())
	_icon.show_upgrade(DAMAGE, _target)


func test_elle_montre_le_titre_et_la_description() -> void:
	assert_str((_icon.get_node("VBoxContainer/Title") as RichTextLabel).text).contains("Dégâts")
	assert_str((_icon.get_node("VBoxContainer/Control/Description") as RichTextLabel).text).contains("150 %")


func test_un_clic_emet_chosen_sans_rien_modifier() -> void:
	var chosen: Array[Upgrade] = []
	_icon.chosen.connect(func(upgrade: Upgrade) -> void: chosen.append(upgrade))
	_icon.button.pressed.emit()
	assert_array(chosen).is_equal([DAMAGE])
	assert_float(_target.get("damage_stat") as float).is_equal(100.0)


func test_avec_le_focus_elle_s_eclaire() -> void:
	_icon.button.grab_focus()
	assert_float(_icon.modulate.r).is_greater(1.0)
	_icon.button.release_focus()
	assert_that(_icon.modulate).is_equal(Color.WHITE)
