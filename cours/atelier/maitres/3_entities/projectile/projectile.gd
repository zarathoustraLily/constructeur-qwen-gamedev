class_name Projectile extends Node3D
## Un projectile tiré depuis une réserve : il file droit à sa vitesse, puis annonce sa fin au bout de sa durée de
## vie ; c'est sa réserve qui le range, il ne se libère jamais lui-même.

## Le projectile a fini sa course : à ranger.
signal expired(projectile: Projectile)

## Sa vitesse, en m/s.
var velocity: Vector3 = Vector3.ZERO
## Le temps qui lui reste, en secondes.
var time_left: float = 0.0


func _ready() -> void:
	process_physics_priority = ProcessOrder.ENTITIES


func _physics_process(delta: float) -> void:
	travel(delta)


## Le lance depuis `from` à la vitesse `speed` pour `lifetime` secondes.
func launch(from: Vector3, speed: Vector3, lifetime: float) -> void:
	position = from
	velocity = speed
	time_left = lifetime


## Avance de `delta` secondes ; à la fin de sa durée de vie, annonce `expired` (une seule fois).
func travel(delta: float) -> void:
	if time_left <= 0.0:
		return
	position += velocity * delta
	time_left -= delta
	if time_left <= 0.0:
		expired.emit(self)
