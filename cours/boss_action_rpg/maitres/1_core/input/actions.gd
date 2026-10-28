class_name Actions extends RefCounted
## Les actions du jeu, par leur nom (celui de project.godot, section [input]). Le code ne parle jamais d'une touche
## ni d'un bouton : il parle d'actions ; chacune a sa touche (ou sa souris) et son entrée de manette.

## Se déplacer.
const MOVE_LEFT: StringName = &"move_left"
## Se déplacer.
const MOVE_RIGHT: StringName = &"move_right"
## Se déplacer.
const MOVE_FORWARD: StringName = &"move_forward"
## Se déplacer.
const MOVE_BACK: StringName = &"move_back"
## Tourner la caméra (stick droit ; la souris est lue à part, en mouvement relatif).
const CAMERA_LEFT: StringName = &"camera_left"
## Tourner la caméra.
const CAMERA_RIGHT: StringName = &"camera_right"
## Tourner la caméra.
const CAMERA_UP: StringName = &"camera_up"
## Tourner la caméra.
const CAMERA_DOWN: StringName = &"camera_down"
## Viser (gâchette gauche, clic droit).
const AIM: StringName = &"aim"
## Tirer (gâchette droite, clic gauche).
const SHOOT: StringName = &"shoot"
## Rouler (B, Espace).
const DODGE: StringName = &"dodge"
## Verrouiller la cible (clic du stick droit, clic de la molette).
const LOCK_ON: StringName = &"lock_on"
## Boire une fiole de soin (X, E).
const HEAL: StringName = &"heal"
## Mettre en pause (Menu, Échap).
const PAUSE: StringName = &"pause"


## Les actions du combat, celles qui doivent marcher à la manette comme au clavier et à la souris.
static func gameplay() -> Array[StringName]:
	return [MOVE_LEFT, MOVE_RIGHT, MOVE_FORWARD, MOVE_BACK, AIM, SHOOT, DODGE, LOCK_ON, HEAL, PAUSE]


## Vrai si l'action `action` a au moins une entrée de manette (bouton ou axe).
static func has_gamepad(action: StringName) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false


## Vrai si l'action `action` a au moins une touche ou un bouton de souris.
static func has_keyboard_or_mouse(action: StringName) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey or event is InputEventMouseButton:
			return true
	return false
