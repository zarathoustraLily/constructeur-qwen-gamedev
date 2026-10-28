class_name HeroGun extends Node3D
## L'arme du héros ; le nœud est sa bouche. Elle tire vers un point visé, à cadence fixe, des projectiles pris dans la
## réserve du niveau ; chaque tir la chauffe (Heat) ; surchauffée, elle ne tire plus jusqu'à refroidir. Pas de
## munitions : le joueur choisit ses rafales.

## Un tir est parti de `origin` vers `direction`.
signal fired(origin: Vector3, direction: Vector3)

## Cadence, chauffe par tir, vitesse, dégâts et durée des projectiles, portée de la visée.
@export var settings: GunSettings

## La réserve des projectiles du niveau, posée par le héros.
var pool: ProjectilePool

## La chaleur de l'arme.
@onready var heat: HeatComponent = $Heat

var _cooldown: float = 0.0


func _ready() -> void:
	process_physics_priority = ProcessOrder.COMPONENTS


func _physics_process(delta: float) -> void:
	tick(delta)


## Fait passer `delta` secondes sur la cadence.
func tick(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)


## Vrai si un tir peut partir : cadence écoulée, arme pas surchauffée, un projectile prêt. Un temps décompté image par
## image n'arrive pas exactement à zéro (0,1 − 6 × 1/60 laisse 3e-17) : « presque zéro » compte comme zéro.
func can_fire() -> bool:
	var ready_to_fire: bool = _cooldown <= 0.0 or is_zero_approx(_cooldown)
	return ready_to_fire and not heat.is_overheated and pool != null and pool.available() > 0


## Tire vers `target` si c'est possible ; rend vrai si un tir est parti.
func pull(target: Vector3) -> bool:
	if not can_fire():
		return false
	var origin: Vector3 = global_position
	var direction: Vector3 = origin.direction_to(target)
	if direction.is_zero_approx():
		direction = Motion.forward_of(global_rotation.y)
	pool.fire(origin, direction, settings.projectile_speed, settings.damage, settings.lifetime)
	_cooldown = settings.fire_interval
	heat.add(settings.heat_per_shot)
	fired.emit(origin, direction)
	return true
