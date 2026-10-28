class_name DummyHitState extends State
## L'état Hit du mannequin : étourdi pendant `hit_stun_time`, puis il demande à revenir au repos (Idle).

## La durée de l'étourdissement.
@export var settings: DummySettings

## Le temps d'étourdissement qui reste, en secondes.
var time_left: float = 0.0


## Repart pour un étourdissement complet, même si un coup précédent n'était pas fini.
func enter(_previous: StringName) -> void:
	time_left = settings.hit_stun_time


## Décompte l'étourdissement ; à zéro, demande Idle.
func physics_update(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0:
		finish(&"Idle")
