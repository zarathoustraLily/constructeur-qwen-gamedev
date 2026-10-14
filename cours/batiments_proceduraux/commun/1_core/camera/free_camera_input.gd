extends Node
## Les entrées de la caméra libre : seul ce script lit le clavier et la souris. Il les traduit en
## intentions pour la caméra (free_camera.gd), qui ne lit jamais les touches elle-même.
##
## Clic droit maintenu et souris : regarder. Déplacement : touches ZQSD d'un clavier AZERTY
## (les touches physiques WASD, quelle que soit la disposition), A et E pour descendre et
## monter, Maj pour aller plus vite.

const FreeCamera := preload("res://1_core/camera/free_camera.gd")

var _camera: FreeCamera


## La caméra à piloter, fournie par la scène qui pose ce nœud.
func setup(camera: FreeCamera) -> void:
	if camera == null:
		push_error("FreeCameraInput : aucune caméra à piloter.")
		return
	_camera = camera


func _unhandled_input(event: InputEvent) -> void:
	if _camera == null:
		return
	if event is InputEventMouseButton:
		var button: InputEventMouseButton = event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_RIGHT:
			if button.pressed:
				_camera.begin_look()
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_camera.look((event as InputEventMouseMotion).relative)


func _physics_process(_delta: float) -> void:
	if _camera == null:
		return
	var move: Vector3 = Vector3(_axis(KEY_A, KEY_D), _axis(KEY_Q, KEY_E), _axis(KEY_W, KEY_S))
	_camera.set_intent(move, Input.is_physical_key_pressed(KEY_SHIFT))


## -1, 0 ou 1 selon la touche tenue (par sa place sur le clavier).
func _axis(negative: Key, positive: Key) -> float:
	return float(Input.is_physical_key_pressed(positive)) - float(Input.is_physical_key_pressed(negative))
