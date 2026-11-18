class_name OrbitInput extends Node
## Les commandes de la caméra (OrbitRig) :
## - à la souris, sur la vue : glisser (bouton gauche ou droit) tourne autour du sujet, la molette rapproche ;
## - à la manette : le stick droit tourne, les gâchettes hautes rapprochent (RB) et éloignent (LB) ;
## - Y à la manette, G au clavier (action toggle_game_view) : bascule entre la vue libre et la vue du jeu.
## Au clavier, J L I K tournent et E Q rapprochent, comme le stick et les gâchettes (actions de project.godot).

## La caméra a bougé, ou changé de vue.
signal rig_changed

## Degrés tournés par pixel glissé.
const DEGREES_PER_PIXEL: float = 0.4
## Degrés tournés par seconde, stick au bout.
const STICK_DEGREES_PER_S: float = 120.0
## Facteur de distance d'un cran de molette vers soi (rapprocher).
const WHEEL_FACTOR: float = 0.9
## Facteur de distance par seconde, gâchette tenue.
const ZOOM_PER_S: float = 0.4

## La caméra commandée.
var rig: OrbitRig = OrbitRig.new()


func _ready() -> void:
	process_priority = ProcessOrder.INPUT


func _process(delta: float) -> void:
	step(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_game_view"):
		toggle_game_view()
		get_viewport().set_input_as_handled()


## Traite un événement de souris reçu par la vue ; vrai s'il a servi.
func handle(event: InputEvent) -> bool:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and (motion.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT)) != 0:
		rig.orbit(-motion.relative.x * DEGREES_PER_PIXEL, motion.relative.y * DEGREES_PER_PIXEL)
		rig_changed.emit()
		return true
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.pressed and button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		rig.zoom(WHEEL_FACTOR if button.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / WHEEL_FACTOR)
		rig_changed.emit()
		return true
	return false


## Applique le stick et les gâchettes pendant `delta` secondes ; vrai si la caméra a bougé.
func step(delta: float) -> bool:
	var stick: Vector2 = Input.get_vector("orbit_left", "orbit_right", "orbit_up", "orbit_down")
	var push: float = Input.get_axis("zoom_in", "zoom_out")
	if stick.is_zero_approx() and is_zero_approx(push):
		return false
	if not stick.is_zero_approx():
		rig.orbit(-stick.x * STICK_DEGREES_PER_S * delta, stick.y * STICK_DEGREES_PER_S * delta)
	if not is_zero_approx(push):
		rig.zoom(pow(ZOOM_PER_S, -push * delta))
	rig_changed.emit()
	return true


## Bascule entre la vue libre et la vue du jeu.
func toggle_game_view() -> void:
	rig.game_view = not rig.game_view
	rig_changed.emit()
