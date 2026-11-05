class_name MapInput
extends Node
## La carte de navigation : un clic (ou un glisser) du bouton gauche sur la carte vue de dessus centre la vue rendue sur le
## point visé. La carte montre, en blanc, le contour de ce que filme la vue rendue (`RoomView.outline_m`).

var _map: RoomView
var _camera: CameraTransform
var _dragging: bool = false


## Écoute la carte `map` et commande la projection de caméra `camera` de la vue rendue.
func setup(map: RoomView, camera: CameraTransform) -> void:
	_map = map
	_camera = camera
	map.gui_input.connect(handle)


## Traduit l'événement `event` ; rend true s'il a servi.
func handle(event: InputEvent) -> bool:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		_dragging = button.pressed
		if button.pressed:
			_camera.center_on(_map.view_transform.screen_to_world(button.position))
		return true
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _dragging:
		_camera.center_on(_map.view_transform.screen_to_world(motion.position))
		return true
	return false


## Le contour au sol (mètres, x et z) de ce que filme une vue de `view_size` pixels.
func footprint(view_size: Vector2) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	for corner: Vector2 in [Vector2.ZERO, Vector2(view_size.x, 0.0), view_size, Vector2(0.0, view_size.y)]:
		var ground: Vector3 = _camera.screen_to_world(corner)
		result.append(Vector2(ground.x, ground.z))
	return result
