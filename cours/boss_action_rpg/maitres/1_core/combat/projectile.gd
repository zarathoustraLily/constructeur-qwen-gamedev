class_name Projectile extends Node3D
## Un projectile du héros, rapide : à chaque image de physique, il lance un rayon sur le trajet qu'il va parcourir ;
## il ne traverse donc jamais un mur ni un bouclier fin, quelle que soit sa vitesse. Il touche le décor (il s'arrête)
## ou une zone qui reçoit les tirs (Hurtbox : elle prend les dégâts) ; sinon il s'éteint au bout de sa durée. Il
## n'est jamais détruit : il retourne à sa réserve (ProjectilePool), qui le relance.

## Le projectile a fini (touché ou éteint) : sa réserve le reprend.
signal finished(projectile: Projectile)
## Il a touché quelque chose en `point`, de normale `normal` ; `dealt` : les dégâts vraiment faits (0 : bloqué ou
## décor).
signal impacted(point: Vector3, normal: Vector3, dealt: float)

## Vrai pendant le vol.
var active: bool = false
## Les dégâts du coup.
var damage: float = 0.0

var _velocity: Vector3 = Vector3.ZERO
var _left: float = 0.0
var _query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()


## Ce que touche un tir : le décor et les zones qui reçoivent les tirs.
static func hit_mask() -> int:
	return Layers.mask([Layers.WORLD, Layers.TARGETS])


func _ready() -> void:
	process_physics_priority = ProcessOrder.PROJECTILES
	_query.collision_mask = hit_mask()
	_query.collide_with_areas = true
	_park()


func _physics_process(delta: float) -> void:
	advance(delta)


## Part de `origin` vers `direction` (longueur 1) à `speed` m/s, avec `amount` dégâts, pour `lifetime` secondes au
## plus ; il s'oriente dans sa direction.
func launch(origin: Vector3, direction: Vector3, speed: float, amount: float, lifetime: float) -> void:
	global_position = origin
	var up: Vector3 = Vector3.UP if absf(direction.y) < 0.99 else Vector3.BACK
	look_at(origin + direction, up)
	_velocity = direction * speed
	damage = amount
	_left = lifetime
	active = true
	visible = true
	set_physics_process(true)


## Avance de `delta` secondes : un rayon sur le trajet ; touché, il s'arrête au point touché et fait ses dégâts ; sa
## durée passée, il s'éteint.
func advance(delta: float) -> void:
	if not active:
		return
	var from: Vector3 = global_position
	_query.from = from
	_query.to = from + _velocity * delta
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(_query)
	if not hit.is_empty():
		var point: Vector3 = hit["position"]
		var normal: Vector3 = hit["normal"]
		var hurtbox: Hurtbox = hit["collider"] as Hurtbox
		var dealt: float = hurtbox.receive(damage) if hurtbox != null else 0.0
		global_position = point
		impacted.emit(point, normal, dealt)
		_finish()
		return
	global_position = _query.to
	_left -= delta
	if _left <= 0.0:
		_finish()


func _finish() -> void:
	_park()
	finished.emit(self)


func _park() -> void:
	active = false
	visible = false
	set_physics_process(false)
