class_name TrainingDummyView extends Node3D
## La vue du mannequin : elle penche en arrière pendant un coup et se couche une fois vaincu, en rejoignant
## l'inclinaison voulue en douceur. Elle lit l'état du mannequin ; elle ne le change jamais.

## Le mannequin montré.
@export var dummy: TrainingDummy
## Les inclinaisons et la vitesse.
@export var settings: DummySettings


func _ready() -> void:
	process_priority = ProcessOrder.VIEWS


func _process(delta: float) -> void:
	rotation.x = approach(rotation.x, target_tilt(dummy.state(), settings), settings.tilt_speed, delta)


## L'inclinaison voulue (en radians, autour de x) pour l'état `state_name`.
static func target_tilt(state_name: StringName, dummy_settings: DummySettings) -> float:
	match state_name:
		&"Hit":
			return -dummy_settings.hit_tilt
		&"Defeated":
			return -dummy_settings.defeated_tilt
		_:
			return 0.0


## `current` rapproché de `target` d'un pas qui ne dépend pas du nombre d'images par seconde (amortissement
## exponentiel : 1 - exp(-vitesse × delta)).
static func approach(current: float, target: float, speed: float, delta: float) -> float:
	return lerpf(current, target, 1.0 - exp(-speed * delta))
