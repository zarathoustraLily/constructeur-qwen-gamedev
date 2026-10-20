extends GdUnitTestSuite
## Règles de l'affichage des commandes : les jauges montrent les gaz et la direction, le texte dit si le frein
## et le saut sont tenus, et quelles manettes sont branchées.

const DISPLAY := preload("res://4_ui/hud/input_display/input_display.tscn")

var _display: InputDisplay


func before_test() -> void:
	_display = auto_free(DISPLAY.instantiate())
	add_child(_display)


func _commands(throttle: float, steering: float, brake: bool, jump_held: bool) -> DriveCommands:
	var commands := DriveCommands.new()
	commands.throttle = throttle
	commands.steering = steering
	commands.brake = brake
	commands.jump_held = jump_held
	return commands


func test_les_jauges_montrent_les_gaz_et_la_direction() -> void:
	_display.show_commands(_commands(0.5, -0.25, false, false), PackedStringArray())
	assert_float((_display.get_node("Panel/Rows/Throttle") as ProgressBar).value).is_equal_approx(0.5, 0.001)
	assert_float((_display.get_node("Panel/Rows/Steering") as ProgressBar).value).is_equal_approx(-0.25, 0.001)


func test_le_frein_et_le_saut_s_affichent() -> void:
	_display.show_commands(_commands(0.0, 0.0, true, true), PackedStringArray())
	assert_str((_display.get_node("Panel/Rows/Buttons") as Label).text).is_equal("Frein : oui   Saut : oui")


func test_les_manettes_branchees_s_affichent() -> void:
	var pads := _display.get_node("Panel/Rows/Pads") as Label
	_display.show_commands(_commands(0.0, 0.0, false, false), PackedStringArray())
	assert_str(pads.text).is_equal("Aucune manette branchée")
	_display.show_commands(_commands(0.0, 0.0, false, false), PackedStringArray(["Xbox Controller"]))
	assert_str(pads.text).is_equal("Manette : Xbox Controller")
