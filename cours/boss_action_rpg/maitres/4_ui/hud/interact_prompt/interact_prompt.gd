class_name InteractPrompt extends Label
## L'invite de la main : ce qu'on peut faire ici, avec le bouton de l'appareil qu'on tient. Le dernier appareil touché
## décide. Rien de plus à brancher : elle lit elle-même les évènements d'entrée.

## Le bouton à la manette.
const GAMEPAD_BUTTON: String = "Y"
## La touche au clavier.
const KEY: String = "F"
## Un stick au repos dérive : il ne compte qu'au-delà de ce seuil.
const STICK_THRESHOLD: float = 0.5

## Vrai si le dernier appareil touché est une manette.
var gamepad: bool = false

var _prompt: String = ""


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		_set_gamepad(true)
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) > STICK_THRESHOLD:
			_set_gamepad(true)
	elif event is InputEventKey or event is InputEventMouse:
		_set_gamepad(false)


## Montre l'invite `prompt` ; vide, elle se cache.
func show_prompt(prompt: String) -> void:
	_prompt = prompt
	_refresh()


func _set_gamepad(value: bool) -> void:
	if value != gamepad:
		gamepad = value
		_refresh()


func _refresh() -> void:
	visible = _prompt != ""
	text = "[%s]  %s" % [GAMEPAD_BUTTON if gamepad else KEY, _prompt]
