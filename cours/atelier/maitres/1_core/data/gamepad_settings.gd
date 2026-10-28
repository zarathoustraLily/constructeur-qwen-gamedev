class_name GamepadSettings extends Resource
## Réglages de la manette : zones mortes, vibrations, et les actions que le joueur peut remapper.

## Rayon de la zone morte des sticks (de 0 à 1) : un stick au repos ne revient jamais tout à fait au centre.
@export_range(0.0, 0.9, 0.01) var stick_deadzone: float = 0.2
## Zone morte des gâchettes (de 0 à 1).
@export_range(0.0, 0.9, 0.01) var trigger_deadzone: float = 0.1
## Les vibrations sont-elles permises ?
@export var rumble_enabled: bool = true
## Part de la force d'un choc donnée au petit moteur (vibration fine).
@export_range(0.0, 1.0, 0.05) var weak_motor_scale: float = 0.6
## Part de la force d'un choc donnée au gros moteur (vibration lourde).
@export_range(0.0, 1.0, 0.05) var strong_motor_scale: float = 1.0
## Force de choc à partir de laquelle le gros moteur tourne.
@export_range(0.0, 1.0, 0.05) var strong_motor_threshold: float = 0.5
## Durée de la vibration d'un choc très léger, en secondes.
@export_range(0.0, 1.0, 0.01) var min_rumble_duration: float = 0.08
## Durée de la vibration d'un choc maximal, en secondes.
@export_range(0.0, 2.0, 0.01) var max_rumble_duration: float = 0.35
## Les actions que le menu des commandes propose de remapper, dans l'ordre affiché.
@export var remappable_actions: Array[StringName] = [&"move_jump", &"move_attack", &"move_dash"]
## Le nom affiché de chaque action remappable.
@export var action_names: Dictionary[StringName, String] = {
	&"move_jump": "Sauter", &"move_attack": "Attaquer", &"move_dash": "Esquiver",
}
