extends GdUnitTestSuite
## Règles de l'affichage des commandes : les jauges montrent la marche, le texte dit la direction de la visée
## (ou son absence), compte les coups et les esquives, nomme l'appareil en cours et les manettes branchées.

const DISPLAY := preload("res://4_ui/hud/input_display/input_display.tscn")

var _display: InputDisplay


func before_test() -> void:
	_display = auto_free(DISPLAY.instantiate())
	add_child(_display)


func _commands(move: Vector2, aim: Vector2) -> PlayerCommands:
	var commands := PlayerCommands.new()
	commands.move = move
	commands.aim = aim
	return commands


func _label(row: String) -> String:
	return (_display.get_node("Panel/Rows/" + row) as Label).text


func test_les_jauges_montrent_la_marche() -> void:
	_display.show_commands(_commands(Vector2(0.5, -0.25), Vector2.ZERO), PackedStringArray())
	assert_float((_display.get_node("Panel/Rows/MoveX") as ProgressBar).value).is_equal_approx(0.5, 0.001)
	assert_float((_display.get_node("Panel/Rows/MoveY") as ProgressBar).value).is_equal_approx(-0.25, 0.001)


func test_la_visee_s_affiche_en_degres_ou_aucune() -> void:
	_display.show_commands(_commands(Vector2.ZERO, Vector2.ZERO), PackedStringArray())
	assert_str(_label("Aim")).is_equal("Visée : aucune (vers la marche)")
	_display.show_commands(_commands(Vector2.ZERO, Vector2(0.0, 3.0)), PackedStringArray())
	assert_str(_label("Aim")).is_equal("Visée : 90°")


func test_les_coups_et_les_esquives_se_comptent() -> void:
	var commands := _commands(Vector2.ZERO, Vector2.ZERO)
	commands.attack = true
	_display.show_commands(commands, PackedStringArray())
	_display.show_commands(commands, PackedStringArray())
	commands.attack = false
	commands.dash = true
	_display.show_commands(commands, PackedStringArray())
	assert_str(_label("Buttons")).is_equal("Coups : 2   Esquives : 1")


func test_l_appareil_et_les_manettes_s_affichent() -> void:
	var commands := _commands(Vector2.ZERO, Vector2.ZERO)
	_display.show_commands(commands, PackedStringArray())
	assert_str(_label("Device")).is_equal("Appareil : clavier et souris")
	assert_str(_label("Pads")).is_equal("Aucune manette branchée")
	commands.from_pad = true
	_display.show_commands(commands, PackedStringArray(["Xbox Controller"]))
	assert_str(_label("Device")).is_equal("Appareil : manette")
	assert_str(_label("Pads")).is_equal("Manette : Xbox Controller")
