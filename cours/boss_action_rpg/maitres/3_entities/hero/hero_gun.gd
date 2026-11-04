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
#@ 1-27
	return ready_to_fire and not heat.is_overheated and pool != null and pool.available() > 0
#@ 28+
	return ready_to_fire and not heat.is_overheated and pool != null and pool.available() >= settings.pellets
#@ all


## Tire vers `target` si c'est possible ; rend vrai si un tir est parti.
func pull(target: Vector3) -> bool:
	if not can_fire():
		return false
	var origin: Vector3 = global_position
	var direction: Vector3 = origin.direction_to(target)
	if direction.is_zero_approx():
		direction = Motion.forward_of(global_rotation.y)
#@ 1-27
	pool.fire(origin, direction, settings.projectile_speed, settings.damage, settings.lifetime)
#@ 28+
	for pellet: int in settings.pellets:
		pool.fire(origin, scattered(direction, pellet), settings.projectile_speed, settings.damage, settings.lifetime)
#@ all
	_cooldown = settings.fire_interval
	heat.add(settings.heat_per_shot)
	fired.emit(origin, direction)
	return true
#@ 28+


## La direction du projectile numéro `pellet` d'un tir : le premier part droit, les autres sur un cercle autour de lui. Le
## motif est fixe : une gerbe se lit, et se teste.
func scattered(direction: Vector3, pellet: int) -> Vector3:
	if pellet == 0:
		return direction
	var side: Vector3 = direction.cross(Vector3.UP if absf(direction.y) < 0.99 else Vector3.RIGHT).normalized()
	var around: float = TAU * (pellet - 1) / (settings.pellets - 1)
	return direction.rotated(side.rotated(direction, around), deg_to_rad(settings.spread_degrees))
#@ all
