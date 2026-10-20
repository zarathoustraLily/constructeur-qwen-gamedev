class_name CameraInput extends Node
## Adaptateur d'entrées de la caméra : le seul script de la caméra qui lit Input (règle ARC-04). Il cumule
## les mouvements de la souris tant qu'elle est capturée, et lit le stick droit par les actions look_left,
## look_right, look_up et look_down (zones mortes dans project.godot). Un clic dans la fenêtre capture la
## souris ; ui_cancel (Échap) la rend. Au démarrage, la souris reste libre : la caméra ne prend pas la main
## de celui qui ne joue pas.

## Vrai quand la souris est capturée et pilote la caméra.
var captured: bool = false

var _mouse_motion: Vector2 = Vector2.ZERO


func _input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed and not captured:
		set_captured(true)
	elif event.is_action_pressed("ui_cancel") and captured:
		set_captured(false)
	var motion := event as InputEventMouseMotion
	if motion != null:
		add_mouse_motion(motion.relative)


## Capture la souris (`value` vrai) pour piloter la caméra, ou la libère.
func set_captured(value: bool) -> void:
	captured = value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE


## Ajoute un mouvement de souris (en pixels) ; ignoré si la souris n'est pas capturée.
func add_mouse_motion(relative: Vector2) -> void:
	if captured:
		_mouse_motion += relative


## Rend le mouvement de souris cumulé depuis le dernier appel, puis le remet à zéro.
func take_mouse_motion() -> Vector2:
	var motion := _mouse_motion
	_mouse_motion = Vector2.ZERO
	return motion


## Position du stick droit, de -1 à 1 sur chaque axe, zone morte remise à l'échelle.
func stick() -> Vector2:
	return Input.get_vector("look_left", "look_right", "look_up", "look_down")
