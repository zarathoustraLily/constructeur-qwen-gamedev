class_name HeroHitState extends State
## L'état Hit du héros : un coup l'a fait chanceler ; il recule, loin du coup, sans pouvoir agir, pendant
## `hit_stun_time`, puis il revient à la course (Move). Ses entrées sont ignorées : un coup reçu se paie.

## Le héros piloté.
@export var hero: Hero

## Le temps écoulé depuis le coup, en secondes.
var elapsed: float = 0.0

var _push: Vector3 = Vector3.ZERO


## Le recul part à l'opposé du coup, à pleine vitesse.
func enter(_previous: StringName) -> void:
	elapsed = 0.0
	_push = hero.knockback_direction() * hero.settings.knockback_speed


## Le recul ralentit jusqu'à l'arrêt ; le chancellement fini, Move.
func physics_update(delta: float) -> void:
	elapsed += delta
	var weight: float = clampf(1.0 - elapsed / hero.settings.hit_stun_time, 0.0, 1.0)
	hero.slide(delta, _push * weight)
	if elapsed >= hero.settings.hit_stun_time:
		finish(&"Move")
