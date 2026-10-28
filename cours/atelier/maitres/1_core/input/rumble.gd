class_name Rumble extends RefCounted
## Les vibrations de la manette, proportionnées à la force d'un choc : le petit moteur pour tous les chocs, le gros
## seulement pour les chocs forts, et une durée qui croît avec la force.


## Les forces des deux moteurs (x : petit moteur, y : gros moteur) pour un choc de force `impact` (de 0 à 1).
static func strengths(impact: float, settings: GamepadSettings) -> Vector2:
	var force: float = clampf(impact, 0.0, 1.0)
	var strong: float = force if force >= settings.strong_motor_threshold else 0.0
	return Vector2(force * settings.weak_motor_scale, strong * settings.strong_motor_scale)


## La durée de la vibration d'un choc de force `impact` (de 0 à 1), en secondes.
static func duration(impact: float, settings: GamepadSettings) -> float:
	return lerpf(settings.min_rumble_duration, settings.max_rumble_duration, clampf(impact, 0.0, 1.0))


## Fait vibrer la manette `device` pour un choc de force `impact` ; rien si les vibrations sont coupées ou si le
## choc est nul.
static func play(device: int, impact: float, settings: GamepadSettings) -> void:
	if not settings.rumble_enabled or impact <= 0.0:
		return
	var motors: Vector2 = strengths(impact, settings)
	Input.start_joy_vibration(device, motors.x, motors.y, duration(impact, settings))
