extends Node
## Exemple : déplacement à la manette. Les actions move_* de project.godot reçoivent le stick gauche et la croix, zone
## morte 0,2. On pousse le stick (Input.parse_input_event, comme une vraie manette) et on lit Input.get_vector : sous
## la zone morte, rien ; au-delà, la course est remise à l'échelle ; en diagonale, la longueur ne dépasse pas 1 ; la
## croix donne une direction pleine.


func _ready() -> void:
	var leger := _vecteur_stick(Vector2(0.15, 0.0))
	var moyen := _vecteur_stick(Vector2(0.6, 0.0))
	var diagonale := _vecteur_stick(Vector2(0.9, -0.9))
	_stick(Vector2.ZERO)
	_croix(JOY_BUTTON_DPAD_LEFT, true)
	var croix := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_croix(JOY_BUTTON_DPAD_LEFT, false)
	var ok := leger == Vector2.ZERO and is_equal_approx(moyen.x, 0.5) and diagonale.length() <= 1.0001
	if ok and diagonale.x > 0.0 and diagonale.y < 0.0 and croix == Vector2.LEFT:
		print("EXEMPLE VERIFIE : stick à 0,15 → %s ; à 0,6 → %s ; en diagonale (0,9 ; -0,9) → %s, longueur %.3f ; croix gauche → %s"
				% [leger, moyen, diagonale, diagonale.length(), croix])
	else:
		push_error("léger %s, moyen %s, diagonale %s (%.3f), croix %s" % [leger, moyen, diagonale, diagonale.length(), croix])
	get_tree().quit()


func _vecteur_stick(position: Vector2) -> Vector2:
	_stick(position)
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


## Le stick gauche de la première manette à `position` (x vers la droite, y vers le bas).
func _stick(position: Vector2) -> void:
	_axe(JOY_AXIS_LEFT_X, position.x)
	_axe(JOY_AXIS_LEFT_Y, position.y)
	Input.flush_buffered_events()


func _axe(axe: JoyAxis, valeur: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = axe
	e.axis_value = valeur
	Input.parse_input_event(e)


func _croix(bouton: JoyButton, appuye: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = bouton
	e.pressed = appuye
	Input.parse_input_event(e)
	Input.flush_buffered_events()
