class_name Fireball extends Node3D
## Une boule de feu du Gardien. Elle grandit d'abord dans sa main (`hold`) : c'est l'annonce. Lancée (`launch`), elle file
## vers sa cible en la suivant un peu, assez peu pour qu'une roulade de côté l'évite. À chaque image de physique, un
## rayon sur son trajet : elle n'entre jamais dans le décor. Elle explose contre le décor, près de sa cible, ou au bout de
## sa durée ; l'explosion frappe sa cible si elle est à portée (`take_hit`, qui respecte l'invulnérabilité de la
## roulade). Elle n'est jamais détruite : cachée, elle attend le prochain sort.

## Elle a explosé en `point`.
signal exploded(point: Vector3)

## Elle vise à cette hauteur au-dessus des pieds de sa cible, en mètres.
const AIM_HEIGHT: float = 1.0

## Sa vitesse, ses rayons, sa durée.
@export var settings: GolemSpellSettings
## L'énergie de sa lumière en vol.
@export_range(0.0, 100.0, 0.1) var light_energy: float = 5.0
## La longueur de sa traîne, en mètres.
@export_range(0.1, 30.0, 0.1) var tail_length: float = 4.0

## Vrai pendant le vol.
var active: bool = false
## Vrai tant qu'elle grandit dans la main du Gardien.
var held: bool = false
## Faux : sa lumière reste éteinte (qualité basse).
var light_allowed: bool = true

var _target: Node3D
var _direction: Vector3 = Vector3.FORWARD
var _damage: float = 0.0
var _left: float = 0.0
var _origin: Vector3 = Vector3.ZERO
var _query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()

@onready var _core: Node3D = $Core
@onready var _tail: Node3D = $Tail
@onready var _flames: GPUParticles3D = $Flames
@onready var _light: OmniLight3D = $Light


func _enter_tree() -> void:
	add_to_group(VfxBurst.GROUP)


func _ready() -> void:
	process_physics_priority = ProcessOrder.PROJECTILES
	_query.collision_mask = Layers.bit(Layers.WORLD)
	_park()


func _physics_process(delta: float) -> void:
	advance(delta)


## Elle est libre : ni dans sa main ni en vol.
func is_free() -> bool:
	return not active and not held


## Tenue en `point`, à `growth` de sa taille (de 0 à 1).
func hold(point: Vector3, growth: float) -> void:
	held = true
	visible = true
	global_position = point
	_core.scale = Vector3.ONE * maxf(growth, 0.01)
	_tail.scale.z = 0.01
	_flames.emitting = true
	_light.visible = light_allowed
	_light.light_energy = light_energy * growth


## Part de `origin` vers `direction` (longueur 1), pour frapper `target` de `damage`.
func launch(origin: Vector3, direction: Vector3, target: Node3D, damage: float) -> void:
	held = false
	active = true
	visible = true
	global_position = origin
	_origin = origin
	_direction = direction
	_target = target
	_damage = damage
	_left = settings.ball_life
	_core.scale = Vector3.ONE
	_flames.emitting = true
	_light.visible = light_allowed
	_light.light_energy = light_energy
	_turn_tail()
	set_physics_process(true)


## Le sort est interrompu : elle s'éteint sans exploser.
func cancel() -> void:
	_park()


## Avance de `delta` secondes : elle se tourne un peu vers sa cible, puis un rayon sur son trajet ; le décor, sa cible ou
## la fin de sa durée la font exploser.
func advance(delta: float) -> void:
	if not active:
		return
	var aim: Vector3 = _target.global_position + Vector3.UP * AIM_HEIGHT
	var toward: Vector3 = global_position.direction_to(aim)
	var angle: float = _direction.angle_to(toward)
	if angle > 0.0001:
		_direction = _direction.slerp(toward, minf(settings.ball_turn * delta / angle, 1.0)).normalized()
	_query.from = global_position
	_query.to = global_position + _direction * settings.ball_speed * delta
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(_query)
	if not hit.is_empty():
		_explode(hit["position"])
		return
	global_position = _query.to
	_turn_tail()
	_left -= delta
	if _left <= 0.0 or global_position.distance_to(aim) <= settings.ball_contact:
		_explode(global_position)


## La traîne va de la boule vers son point de départ, sans le dépasser (échelle Z du plan : tracer.gdshader).
func _turn_tail() -> void:
	var up: Vector3 = Vector3.UP if absf(_direction.y) < 0.99 else Vector3.BACK
	look_at(global_position + _direction, up)
	_tail.scale.z = clampf(global_position.distance_to(_origin), 0.01, tail_length)


func _explode(point: Vector3) -> void:
	var aim: Vector3 = _target.global_position + Vector3.UP * AIM_HEIGHT
	_park()
	exploded.emit(point)
	if point.distance_to(aim) <= settings.blast_radius and _target.has_method(&"take_hit"):
		_target.call(&"take_hit", _damage, point)


func _park() -> void:
	active = false
	held = false
	visible = false
	_flames.emitting = false
	set_physics_process(false)
